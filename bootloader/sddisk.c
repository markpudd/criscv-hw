/*
 * sd_boot_test.c - read boot.bin from raw SD sectors over SPI and print it.
 *
 * Freestanding: no stdio, no syscalls, no libc. All output goes straight
 * to the UART registers. Build with e.g.
 *   -ffreestanding -nostdlib -nostartfiles  (plus your own crt0 + linker script)
 *
 * boot.bin is expected at BOOT_SECTOR, written with e.g.
 *   sudo dd if=boot.bin of=/dev/sdX bs=512 seek=1 conv=sync
 * Output stops at the first NUL byte (conv=sync pads the last sector with 0s)
 * or after BOOT_SECTORS sectors.
 *
 * SD in SPI mode: SPI mode 0 per spec (mode 3 usually works too),
 * init clock 100-400 kHz, then up to 25 MHz.
 *
 * ASSUMPTIONS - adjust to match your peripherals:
 *   SPI:
 *   - Writing SPI_TX starts an 8-clock transfer; SPI_STATUS bit 0 = busy;
 *     SPI_RX holds the received byte.
 *   - CS is under software control (spi_cs()) and can be held high while
 *     clocking - the card needs >=74 clocks with CS high at power-up.
 *   - spi_set_speed() selects a slow (<=400 kHz) or fast clock.
 *   UART:
 *   - Writing UART_TX sends one byte; UART_STATUS bit 0 = TX busy/full.
 *   - Addresses below are placeholders - set them to your memory map.
 *   Startup:
 *   - crt0 sets up sp and zeroes .bss (sd_hc and sector_buf rely on it).
 */

 #include <stdint.h>             /* freestanding header, no libc needed */
 #include "sddisk.h"             /* make sure this doesn't pull in stdio.h */
 
 /* ---------- memory-mapped I/O ---------- */
 
 #define UART_TX     (*(volatile uint8_t *)0xFFFFFF00u)
 #define UART_STATUS (*(volatile uint8_t *)0xFFFFFF01u)
 #define UART_BUSY   0x01u
 
 #define SPI_TX      (*(volatile uint8_t *)0xFFFFFF10u)
 #define SPI_STATUS  (*(volatile uint8_t *)0xFFFFFF11u)
 #define SPI_RX      (*(volatile uint8_t *)0xFFFFFF12u)
 #define SPI_BUSY    0x01u
 
 #define BOOT_SECTOR   1u        /* matches dd seek=1 */
 #define BOOT_SECTORS  8u        /* read at most 4 KiB */
 
 #define ACMD41_TRIES  20000u    /* ~1 s or more at ~1-2 MHz SPI */
 #define TOKEN_TRIES   100000u
 #define READY_TRIES   50000u
 
 static int sd_hc;               /* 1 = SDHC/SDXC (block addressed) */
 static uint8_t sector_buf[512];
 
 /* ---------- UART output ---------- */
 
 static void uart_putc(char c)
 {
     if (c == '\n')              /* serial terminals want CRLF */
         uart_putc('\r');
     while (UART_STATUS & UART_BUSY)
         ;
     UART_TX = (uint8_t)c;
 }
 
 static void uart_puts(const char *s)
 {
     while (*s)
         uart_putc(*s++);
 }
 
 /* Print the low 'digits' nibbles of v as uppercase hex, zero padded. */
 static void uart_puthex(uint32_t v, unsigned digits)
 {
     static const char hex[] = "0123456789ABCDEF";
 
     while (digits--)
         uart_putc(hex[(v >> (digits * 4u)) & 0xFu]);
 }
 
 /* Unsigned decimal without division, so no libgcc __udivsi3 needed
  * even on an RV32I-only build. */
 static void uart_putdec(uint32_t v)
 {
     static const uint32_t pow10[] = {
         1000000000u, 100000000u, 10000000u, 1000000u, 100000u,
         10000u, 1000u, 100u, 10u, 1u
     };
     unsigned i;
     int started = 0;
 
     for (i = 0; i < 10; i++) {
         char d = '0';
         while (v >= pow10[i]) {
             v -= pow10[i];
             d++;
         }
         if (d != '0' || started || i == 9) {
             uart_putc(d);
             started = 1;
         }
     }
 }
 
 /* ---------- low-level SPI (fill in the TODOs) ---------- */
 
 static void spi_cs(int active)
 {
     (void)active;
     /* TODO: drive SD CS low when active, high otherwise */
 }
 
 static void spi_set_speed(int fast)
 {
     (void)fast;
     /* TODO: slow = <=400 kHz for init, fast = up to 25 MHz */
 }
 
 static uint8_t spi_xfer(uint8_t out)
 {
     while (SPI_STATUS & SPI_BUSY)
         ;
     SPI_TX = out;
     while (SPI_STATUS & SPI_BUSY)
         ;
     return SPI_RX;
 }
 
 /* ---------- SD protocol ---------- */
 
 static void sd_select(void)
 {
     uint32_t i;
 
     spi_cs(1);
     /* Wait for the card to release busy (DO held high). */
     for (i = 0; i < READY_TRIES; i++)
         if (spi_xfer(0xFF) == 0xFF)
             break;
 }
 
 static void sd_deselect(void)
 {
     spi_cs(0);
     spi_xfer(0xFF);             /* extra clocks so the card releases DO */
 }
 
 /* Send a command frame and return the R1 response (0xFF = no response). */
 static uint8_t sd_cmd(uint8_t cmd, uint32_t arg, uint8_t crc)
 {
     uint8_t r = 0xFF;
     int i;
 
     spi_xfer((uint8_t)(0x40u | cmd));
     spi_xfer((uint8_t)(arg >> 24));
     spi_xfer((uint8_t)(arg >> 16));
     spi_xfer((uint8_t)(arg >> 8));
     spi_xfer((uint8_t)arg);
     spi_xfer(crc);              /* CRC only checked for CMD0/CMD8 */
 
     for (i = 0; i < 10; i++) {
         r = spi_xfer(0xFF);
         if (!(r & 0x80))        /* R1 has bit 7 clear */
             break;
     }
     return r;
 }
 
 /* "<msg>0xNN\n" - the common error-report shape. */
 static void report_r1(const char *msg, uint8_t r)
 {
     uart_puts(msg);
     uart_puts("0x");
     uart_puthex(r, 2);
     uart_putc('\n');
 }
 
 int sddisk_init(void)
 {
     uint8_t r = 0xFF, resp[4];
     uint32_t i;
     int v2 = 0;
 
     spi_set_speed(0);
 
     /* >=74 clocks with CS high to enter native mode. */
     spi_cs(0);
     for (i = 0; i < 10; i++)
         spi_xfer(0xFF);
 
     /* CMD0: GO_IDLE_STATE -> enter SPI mode. Expect R1 = 0x01. */
     sd_select();
     r = sd_cmd(0, 0, 0x95);
     sd_deselect();
     if (r != 0x01) {
         report_r1("CMD0 failed, R1=", r);
         return -1;
     }
 
     /* CMD8: SEND_IF_COND, 2.7-3.6 V, check pattern 0xAA. */
     sd_select();
     r = sd_cmd(8, 0x000001AAu, 0x87);
     if (r == 0x01) {
         for (i = 0; i < 4; i++)
             resp[i] = spi_xfer(0xFF);
         v2 = 1;
         if ((resp[2] & 0x0F) != 0x01 || resp[3] != 0xAA) {
             sd_deselect();
             uart_puts("CMD8 bad echo ");
             uart_puthex(resp[2], 2);
             uart_putc(' ');
             uart_puthex(resp[3], 2);
             uart_putc('\n');
             return -1;
         }
     }                           /* 0x05 = illegal command -> SD v1 card */
     sd_deselect();
 
     /* ACMD41 until the card leaves idle. HCS bit set for v2 cards. */
     for (i = 0; i < ACMD41_TRIES; i++) {
         sd_select();
         sd_cmd(55, 0, 0x01);
         r = sd_cmd(41, v2 ? 0x40000000u : 0, 0x01);
         sd_deselect();
         if (r == 0x00)
             break;
     }
     if (r != 0x00) {
         report_r1("ACMD41 timeout, R1=", r);
         return -1;
     }
 
     /* CMD58: READ_OCR -> CCS bit tells us block vs byte addressing. */
     sd_hc = 0;
     if (v2) {
         sd_select();
         r = sd_cmd(58, 0, 0x01);
         for (i = 0; i < 4; i++)
             resp[i] = spi_xfer(0xFF);
         sd_deselect();
         if (r == 0x00 && (resp[0] & 0x40))
             sd_hc = 1;
     }
 
     /* Standard-capacity cards: force 512-byte blocks. */
     if (!sd_hc) {
         sd_select();
         r = sd_cmd(16, 512, 0x01);
         sd_deselect();
         if (r != 0x00) {
             report_r1("CMD16 failed, R1=", r);
             return -1;
         }
     }
 
     spi_set_speed(1);
   //  uart_puts("SD init OK: ");
   //  uart_puts(!v2 ? "SD v1" : (sd_hc ? "SDHC/SDXC" : "SDSC v2"));
  //   uart_puts(" card\n");
     return 0;
 }
 
 /* CMD17: read one 512-byte block. */
 int sddisk_read_block(uint32_t lba, uint8_t *buf)
 {
     uint8_t r, token = 0xFF;
     uint32_t i;
 
     sd_select();
     r = sd_cmd(17, sd_hc ? lba : lba * 512u, 0x01);
     if (r != 0x00) {
         sd_deselect();
         report_r1("CMD17 failed, R1=", r);
         return -1;
     }
 
     for (i = 0; i < TOKEN_TRIES; i++) {
         token = spi_xfer(0xFF);
         if (token != 0xFF)
             break;
     }
     if (token != 0xFE) {
         sd_deselect();
         report_r1("Bad data token ", token);
         return -1;
     }
 
     for (i = 0; i < 512; i++)
         buf[i] = spi_xfer(0xFF);
     spi_xfer(0xFF);             /* discard CRC16 */
     spi_xfer(0xFF);
     sd_deselect();
     return 0;
 }
 
 #ifdef SDDISK_STANDALONE_TEST
 /* ---------- test ---------- */
 
 static void hexdump(const uint8_t *p, unsigned n)
 {
     unsigned i, j;
 
     for (i = 0; i < n; i += 16) {
         uart_puthex(i, 4);
         uart_puts(": ");
         for (j = 0; j < 16; j++) {
             uart_puthex(p[i + j], 2);
             uart_putc(' ');
         }
         uart_putc(' ');
         for (j = 0; j < 16; j++) {
             uint8_t c = p[i + j];
             uart_putc(c >= 0x20 && c < 0x7F ? (char)c : '.');
         }
         uart_putc('\n');
     }
 }
 
 int main(void)
 {
     uint32_t s;
     unsigned i;
     int done = 0;
 
     uart_puts("SD boot.bin test\n");
 
     if (sddisk_init() != 0) {
         uart_puts("SD init failed\n");
         for (;;)
             ;
     }
 
     for (s = 0; s < BOOT_SECTORS && !done; s++) {
         if (sddisk_read_block(BOOT_SECTOR + s, sector_buf) != 0) {
             uart_puts("Read failed at sector ");
             uart_putdec(BOOT_SECTOR + s);
             uart_putc('\n');
             break;
         }
 
         if (s == 0) {
             uart_puts("First 64 bytes of sector ");
             uart_putdec(BOOT_SECTOR);
             uart_puts(":\n");
             hexdump(sector_buf, 64);
             uart_puts("--- boot.bin contents ---\n");
         }
 
         for (i = 0; i < 512; i++) {
             uint8_t c = sector_buf[i];
             if (c == 0) {       /* end of text / dd padding */
                 done = 1;
                 break;
             }
             if (c == '\n' || c == '\r' || c == '\t' ||
                 (c >= 0x20 && c < 0x7F))
                 uart_putc((char)c);
             else
                 uart_putc('.');
         }
     }
 
     uart_puts("\n--- end ---\n");
 
     for (;;)
         ;
 
     return 0;
 }
 #endif