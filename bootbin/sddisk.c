/*
 * sd_boot_test.c - read boot.bin from raw SD sectors over SPI and print it.
 *
 * boot.bin is expected at BOOT_SECTOR, written with e.g.
 *   sudo dd if=boot.bin of=/dev/sdX bs=512 seek=1 conv=sync
 * Output stops at the first NUL byte (conv=sync pads the last sector with 0s)
 * or after BOOT_SECTORS sectors.
 *
 * SD in SPI mode: SPI mode 0 per spec (mode 3 usually works too),
 * init clock 100-400 kHz, then up to 25 MHz.
 *
 * ASSUMPTIONS - adjust to match your peripheral:
 *   - Writing SPI_TX starts an 8-clock transfer; SPI_STATUS bit 0 = busy;
 *     SPI_RX holds the received byte.
 *   - CS is under software control (spi_cs()) and can be held high while
 *     clocking - the card needs >=74 clocks with CS high at power-up.
 *   - spi_set_speed() selects a slow (<=400 kHz) or fast clock.
 */

#include <stdint.h>
#include <stdio.h>
#include "sddisk.h"

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
        printf("CMD0 failed, R1=0x%02X\n", (unsigned)r);
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
            printf("CMD8 bad echo %02X %02X\n",
                   (unsigned)resp[2], (unsigned)resp[3]);
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
        printf("ACMD41 timeout, R1=0x%02X\n", (unsigned)r);
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
            printf("CMD16 failed, R1=0x%02X\n", (unsigned)r);
            return -1;
        }
    }

    spi_set_speed(1);
    printf("SD init OK: %s card\n",
           !v2 ? "SD v1" : (sd_hc ? "SDHC/SDXC" : "SDSC v2"));
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
        printf("CMD17 failed, R1=0x%02X\n", (unsigned)r);
        return -1;
    }

    for (i = 0; i < TOKEN_TRIES; i++) {
        token = spi_xfer(0xFF);
        if (token != 0xFF)
            break;
    }
    if (token != 0xFE) {
        sd_deselect();
        printf("Bad data token 0x%02X\n", (unsigned)token);
        return -1;
    }

    for (i = 0; i < 512; i++)
        buf[i] = spi_xfer(0xFF);
    spi_xfer(0xFF);             /* discard CRC16 */
    spi_xfer(0xFF);
    sd_deselect();
    return 0;
}


#define WRITE_BUSY_TRIES  1000000u  /* spec allows up to 250 ms (SDHC) / 500 ms (SDXC) */

/* CMD24: write one 512-byte block. */
int sddisk_write_block(uint32_t lba, const uint8_t *buf)
{
    uint8_t r, resp = 0xFF, status;
    uint32_t i;

    sd_select();
    r = sd_cmd(24, sd_hc ? lba : lba * 512u, 0x01);
    if (r != 0x00) {
        sd_deselect();
        printf("CMD24 failed, R1=0x%02X\n", (unsigned)r);
        return -1;
    }

    spi_xfer(0xFF);             /* >=1 byte gap before the data token */
    spi_xfer(0xFE);             /* start block token (single-block write) */
    for (i = 0; i < 512; i++)
        spi_xfer(buf[i]);
    spi_xfer(0xFF);             /* dummy CRC16 (not checked in SPI mode) */
    spi_xfer(0xFF);

    /* Data response token: xxx0sss1, sss = 010 accepted,
       101 CRC error, 110 write error. */
    for (i = 0; i < 10; i++) {
        resp = spi_xfer(0xFF);
        if ((resp & 0x11) == 0x01)
            break;
    }
    if ((resp & 0x1F) != 0x05) {
        sd_deselect();
        printf("Write rejected, data resp=0x%02X\n", (unsigned)resp);
        return -1;
    }

    /* Card holds DO low while it programs the flash. */
    for (i = 0; i < WRITE_BUSY_TRIES; i++)
        if (spi_xfer(0xFF) != 0x00)
            break;
    if (i == WRITE_BUSY_TRIES) {
        sd_deselect();
        printf("Write busy timeout\n");
        return -1;
    }
    sd_deselect();

    /* CMD13: SEND_STATUS (R2) to confirm programming succeeded. */
    sd_select();
    r = sd_cmd(13, 0, 0x01);
    status = spi_xfer(0xFF);
    sd_deselect();
    if (r != 0x00 || status != 0x00) {
        printf("Write status error, R1=0x%02X R2=0x%02X\n",
               (unsigned)r, (unsigned)status);
        return -1;
    }
    return 0;
}


#ifdef SDDISK_STANDALONE_TEST
/* ---------- test ---------- */

static void hexdump(const uint8_t *p, unsigned n)
{
    unsigned i, j;

    for (i = 0; i < n; i += 16) {
        printf("%04X: ", i);
        for (j = 0; j < 16; j++)
            printf("%02X ", (unsigned)p[i + j]);
        printf(" ");
        for (j = 0; j < 16; j++) {
            uint8_t c = p[i + j];
            putchar(c >= 0x20 && c < 0x7F ? c : '.');
        }
        printf("\n");
    }
}

int main(void)
{
    uint32_t s;
    unsigned i;
    int done = 0;

    printf("SD boot.bin test\n");

    if (sddisk_init() != 0) {
        printf("SD init failed\n");
        for (;;)
            ;
    }

    for (s = 0; s < BOOT_SECTORS && !done; s++) {
        if (sddisk_read_block(BOOT_SECTOR + s, sector_buf) != 0) {
            printf("Read failed at sector %u\n",
                   (unsigned)(BOOT_SECTOR + s));
            break;
        }

        if (s == 0) {
            printf("First 64 bytes of sector %u:\n", BOOT_SECTOR);
            hexdump(sector_buf, 64);
            printf("--- boot.bin contents ---\n");
        }

        for (i = 0; i < 512; i++) {
            uint8_t c = sector_buf[i];
            if (c == 0) {       /* end of text / dd padding */
                done = 1;
                break;
            }
            if (c == '\n' || c == '\r' || c == '\t' ||
                (c >= 0x20 && c < 0x7F))
                putchar(c);
            else
                putchar('.');
        }
    }

    printf("\n--- end ---\n");

    for (;;)
        ;

    return 0;
}
#endif