/* SD card block interface used by the FatFs disk adapter. */
#ifndef SDDISK_H
#define SDDISK_H

#include <stdint.h>

int sddisk_init(void);
int sddisk_read_block(uint32_t lba, uint8_t *buf);

#endif