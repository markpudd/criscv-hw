//
//  ymodem.h - minimal YMODEM (CRC / 1K) receiver for the CRISC-V bootloader
//
#ifndef YMODEM_H
#define YMODEM_H

#define YM_OK            0
#define YM_ERR_CANCEL   (-1)   // sender cancelled (CAN CAN)
#define YM_ERR_TIMEOUT  (-2)   // nobody started sending
#define YM_ERR_TOOBIG   (-3)   // file larger than its load region
#define YM_ERR_PROTO    (-4)   // too many errors / out-of-sequence block

#define YM_TYPE_PROG 0
#define YM_TYPE_DATA 1

typedef struct {
  char         name[20];
  int          type;     // YM_TYPE_PROG / YM_TYPE_DATA
  unsigned int length;   // exact file length from the YMODEM header
} ym_file_t;

// Receive one file. force_type: -1 = auto (ELF magic -> program, else data),
// 0/1 = force program/data. Programs land at prog_base, data at data_base.
int ym_receive(unsigned char *prog_base, unsigned int prog_max,
               unsigned char *data_base, unsigned int data_max,
               int force_type, ym_file_t *out);

#endif
