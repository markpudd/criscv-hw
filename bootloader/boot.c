//
//  stage1.c - minimal M9K boot stage (no filesystem)
//
//  Loads the stage 2 ELF from raw sectors starting at BOOT_LBA, written with:
//    diskutil unmountDisk /dev/diskN
//    sudo dd if=build/boot.elf of=/dev/rdiskN bs=512 seek=1 conv=sync
//
//  The ELF file is copied as-is to BOOT_BASE. It must be linked with
//  -Wl,-N -Wl,-Ttext-segment=BOOT_BASE so the file image sits at its link
//  address. Stage 1 checks that, zeroes .bss (stage 2 has no crt0) and jumps
//  to e_entry.
//
#include <stdint.h>
#include "sddisk.h"
// ---- adapt to your sddisk API ------------------------------------------------
//extern int sddisk_init(void);                              // 0 = OK
//extern int sddisk_read_block(uint32_t lba, uint8_t *buf);  // 0 = OK, 512 bytes
// -------------------------------------------------------------------------------

#define LED         (*(volatile unsigned char *)0xFFFFFF00)
#define UART        (*(volatile unsigned char *)0xffffff01)
#define UART_STATUS (*(volatile unsigned char *)0xffffff02)

#define DEBUG_ADD1 (*(volatile int *)0x00003e00)
#define DEBUG_ADD2 (*(volatile int *)0x00003e04)

#define BOOT_LBA    1u                        // dd ... seek=1
#define BOOT_BASE   ((uint8_t *)0xC00000)     // must match -Ttext-segment

static void putch(char c) { while(UART_STATUS & 1) {}; UART = c; }
//static void putchi(int c) { while(UART_STATUS & 1) {}; UART = c; }


static void uart_puts(const char *s)
{
    while (*s)
    putch(*s++);
}


// Byte-wise little-endian reads (strict alignment)
static uint32_t le32(const uint8_t *p) { return p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24); }

static void __attribute__((noreturn)) die(char code) {   // 'E'+code on UART, blink forever
  putch('E'); putch(code); putch('\n');
  for(;;) { LED ^= 1; for(volatile int d = 0; d < 400000; d++) {}; }
}

static void rd(uint32_t lba, uint8_t *buf) {
  if(sddisk_read_block(lba, buf)) die('r');
}

int main(void) {
  uint8_t *b = BOOT_BASE;
  /*volatile unsigned int w;
  volatile unsigned char *ba = (volatile unsigned char *)&w;
  volatile signed char   *sb = (volatile signed char *)&w;
  #define RESULTS ((volatile unsigned int *)0x00003a00) 
  #define RESULTS2 ((volatile unsigned char *)0x00003b00) 

  for (unsigned char i = 0; i < 24; i++) {
    RESULTS2[i] = i;
 //   print_hex(w);   // expect 112233AA, 1122AA44, 11AA3344, AA223344
}
RESULTS2[28] = 0xaa;
RESULTS2[29] = 0xbb;
RESULTS2[30] = 0xcc;
RESULTS2[31] = 0xdd;
  for (int i = 0; i < 4; i++) {
      w = 0x11223344;
      ba[i] = 0xAA;
      RESULTS[i] = w;
   //   print_hex(w);   // expect 112233AA, 1122AA44, 11AA3344, AA223344
  }
    // Load side (lbu): expect 000000BB, 000000AA, 00000099, 00000088
    w = 0x8899AABB;
    for (int i = 0; i < 4; i++)
        RESULTS[4 + i] = b[i];

    // lb sign extension: expect FFFFFF88
    RESULTS[8] = (int)sb[3];

    RESULTS[9] = 0xC0FFEE00; 

  while(UART_STATUS & 1) {}; UART = 'X'; 
  putchC();
  putchi('A');
  while(UART_STATUS & 1) {}; UART = 'Y'; 
  while(UART_STATUS & 1) {}; UART = 'Z'; 
  */
  uart_puts("Starting Boot\n");
 
  if (sddisk_init() != 0) {
    uart_puts("SD init failed\n");
    for (;;)
        ;
}
uart_puts("SD init Passed\n");
  // First sector holds the ELF header and the program header (e_phoff = 52)
  rd(BOOT_LBA, b);
  if(le32(b) != 0x464C457F) die('e');                     // "\x7fELF"
  uint8_t *ph = b + le32(b + 0x1C);                        // e_phoff
  uint32_t off = le32(ph + 4), vaddr = le32(ph + 8);
  if(vaddr - off != (uint32_t)b) die('l');                 // linked for BOOT_BASE?

  // Read the rest of the loadable part: file bytes 0 .. p_offset + p_filesz
  uint32_t end = off + le32(ph + 16);
  for(uint32_t i = 1; (i << 9) < end; i++)
    rd(BOOT_LBA + i, b + (i << 9));

  // No crt0 in stage 2: zero .bss/.sbss (p_filesz .. p_memsz)
  for(uint8_t *p = (uint8_t *)vaddr + le32(ph + 16); p < (uint8_t *)vaddr + le32(ph + 20); p++)
    *p = 0;

  putch('J'); putch('\n');
  uart_puts("Starting main bootloader\n");
  ((void (*)(void))le32(b + 0x18))();                     // e_entry
  die('x');
}