//
//  ymodem.c - minimal YMODEM (CRC / 1K) receiver for the CRISC-V bootloader
//
//  Polled UART, no libc, no tables, RV32I-safe. Blocks are written straight
//  to their load address. The first data block is parked at prog_base; if it
//  isn't an ELF (or data was forced) it is moved to data_base.
//
//  Session:  C -> blk0(name,size) -> ACK C -> blk1..n (ACK each)
//            -> EOT NAK EOT ACK C -> null blk0 -> ACK   (one file per session)
//
#include "ymodem.h"

#ifndef YM_TIMEOUT_LOOPS
#define YM_TIMEOUT_LOOPS 2000000   // status polls per ~1s timeout: calibrate to your clock
#endif
#define YM_START_TRIES 60          // 'C' prompts while waiting for the sender
#define YM_MAX_ERRORS  10

#ifndef YM_HOST_TEST
#define YM_UART        (*(volatile unsigned char *)0xffffff01)
#define YM_UART_STATUS (*(volatile unsigned char *)0xffffff02)
#define YM_UART_IN     (*(volatile unsigned char *)0xffffff03)
#define ym_rx_ready()  (YM_UART_STATUS & 0x02)
#define ym_rx()        (YM_UART_IN)
#define ym_tx_busy()   (YM_UART_STATUS & 0x01)
#define ym_tx(c)       (YM_UART = (c))
#else
int  ym_rx_ready(void);
int  ym_rx(void);
int  ym_tx_busy(void);
void ym_tx(unsigned char c);
#endif

#define SOH 0x01
#define STX 0x02
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CAN 0x18

static int ym_getc(int t) {
  while(!ym_rx_ready())
    if(--t <= 0) return -1;
  return ym_rx() & 0xFF;
}

static void ym_putc(int c) {
  while(ym_tx_busy()) {};
  ym_tx(c);
}

// wait for the line to go quiet (lets the sender finish a bad block)
static void ym_purge(void) {
  while(ym_getc(YM_TIMEOUT_LOOPS >> 3) >= 0) {};
}

static int ym_cancel(int err) {
  ym_putc(CAN); ym_putc(CAN); ym_putc(CAN);
  return err;
}

int ym_receive(unsigned char *prog_base, unsigned int prog_max,
               unsigned char *data_base, unsigned int data_max,
               int force_type, ym_file_t *out) {
  unsigned char *dest = prog_base;
  unsigned int max = prog_max, pos = 0, size = 0;
  unsigned char expect = 1;
  int want_hdr = 1;                      // waiting for a block 0 header
  int have_hdr = 0, done = 0, tries = 0, errors = 0;
  int c, len, blk, nblk, i;

  out->name[0] = 0;
  out->type = YM_TYPE_PROG;
  out->length = 0;

  ym_putc('C');                          // request CRC mode

  for(;;) {
    c = ym_getc(YM_TIMEOUT_LOOPS);

    if(c < 0) {                          // timeout
      if(!have_hdr) {
        if(++tries > YM_START_TRIES) return ym_cancel(YM_ERR_TIMEOUT);
        ym_putc('C');
      } else {
        if(++errors > YM_MAX_ERRORS) return ym_cancel(YM_ERR_PROTO);
        ym_putc(want_hdr ? 'C' : NAK);
      }
      continue;
    }
    if(c == EOT && have_hdr && !done) {
      // NAK the first EOT so a corrupted data byte can't end the file early
      ym_putc(NAK);
      if(ym_getc(YM_TIMEOUT_LOOPS) != EOT) continue;
      ym_putc(ACK);
      done = 1;
      want_hdr = 1;
      out->length = (size && size < pos) ? size : pos;
      ym_putc('C');                      // ask for the closing null header
      continue;
    }
    if(c == CAN) {
      if(ym_getc(YM_TIMEOUT_LOOPS) == CAN) return YM_ERR_CANCEL;
      continue;
    }
    if(c != SOH && c != STX) {           // noise / mangled block header
      if(have_hdr) {
        if(++errors > YM_MAX_ERRORS) return ym_cancel(YM_ERR_PROTO);
        ym_purge();
        ym_putc(want_hdr ? 'C' : NAK);
      }
      continue;
    }

    len  = (c == STX) ? 1024 : 128;
    blk  = ym_getc(YM_TIMEOUT_LOOPS);
    nblk = ym_getc(YM_TIMEOUT_LOOPS);

    // data goes straight to its final place (or is discarded if it wouldn't fit)
    unsigned char *p = (pos + len <= max) ? dest + pos : 0;
    unsigned int crc = 0;
    int ok = (blk >= 0 && nblk >= 0 && (blk ^ nblk) == 0xFF);
    for(i = 0; i < len + 2 && ok; i++) {
      c = ym_getc(YM_TIMEOUT_LOOPS);
      if(c < 0) { ok = 0; break; }
      if(p && i < len) p[i] = c;
      crc ^= (unsigned int)c << 8;       // CRC-16/XMODEM; running it over the
      for(int b = 0; b < 8; b++)         // two CRC bytes too leaves 0 if good
        crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : (crc << 1);
    }
    if(!ok || (crc & 0xFFFF)) {
      if(++errors > YM_MAX_ERRORS) return ym_cancel(YM_ERR_PROTO);
      ym_purge();
      ym_putc(want_hdr ? 'C' : NAK);
      continue;
    }
    errors = 0;

    // ---- header block (block 0) ------------------------------------------
    if(blk == 0 && want_hdr) {
      if(!p) return ym_cancel(YM_ERR_PROTO);
      ym_putc(ACK);
      if(done || p[0] == 0) {            // null header ends the batch
        if(!done) return YM_ERR_PROTO;   // empty batch
        if(p[0]) ym_cancel(0);           // more files queued: refuse them
        return YM_OK;
      }
      // "name\0size mtime mode ...\0"
      for(i = 0; p[i] && i < (int)sizeof(out->name) - 1; i++) out->name[i] = p[i];
      out->name[i] = 0;
      while(i < len && p[i]) i++;
      for(i++, size = 0; i < len && p[i] >= '0' && p[i] <= '9'; i++)
        size = (size << 3) + (size << 1) + (unsigned int)(p[i] - '0');
      have_hdr = 1;
      want_hdr = 0;
      ym_putc('C');                      // start the data phase
      continue;
    }
    if(blk == 0 && pos == 0) {           // header resent (our ACK was lost)
      ym_putc(ACK);
      ym_putc('C');
      continue;
    }

    // ---- data blocks -----------------------------------------------------
    if(!have_hdr || done) continue;
    if(blk == ((expect - 1) & 0xFF)) {   // duplicate (our ACK was lost)
      ym_putc(ACK);
      continue;
    }
    if(blk != expect) return ym_cancel(YM_ERR_PROTO);
    if(!p) return ym_cancel(YM_ERR_TOOBIG);

    if(pos == 0) {                       // first block: decide where it all goes
      int is_elf = p[0] == 0x7F && p[1] == 'E' && p[2] == 'L' && p[3] == 'F';
      out->type = (force_type >= 0) ? force_type : (is_elf ? YM_TYPE_PROG : YM_TYPE_DATA);
      if(out->type == YM_TYPE_DATA) {
        for(i = 0; i < len; i++) data_base[i] = prog_base[i];
        dest = data_base;
        max = data_max;
      }
      if(size > max) return ym_cancel(YM_ERR_TOOBIG);
    }
    pos += len;
    expect++;
    ym_putc(ACK);
  }
}
