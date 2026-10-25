/*
 * diskio.c - FatFs low-level disk I/O for a single SD card over SPI.
 *
 * Physical drive 0 only. Read-only unless FF_FS_READONLY == 0, in which
 * case sd_write_block() and sd_wait_ready() must be provided by sd_spi.c.
 */

#include "ff.h"
#include "diskio.h"
#include "../sddisk.h"

static volatile DSTATUS stat = STA_NOINIT;

DSTATUS disk_status(BYTE pdrv)
{
    if (pdrv != 0)
        return STA_NOINIT;
    return stat;
}

DSTATUS disk_initialize(BYTE pdrv)
{
    if (pdrv != 0)
        return STA_NOINIT;

    if (sd_init() == 0)
        stat &= (DSTATUS)~STA_NOINIT;
    else
        stat |= STA_NOINIT;

#if FF_FS_READONLY
    stat |= STA_PROTECT;
#endif
    return stat;
}

DRESULT disk_read(BYTE pdrv, BYTE *buff, LBA_t sector, UINT count)
{
    if (pdrv != 0 || count == 0)
        return RES_PARERR;
    if (stat & STA_NOINIT)
        return RES_NOTRDY;

    while (count--) {
        if (sd_read_block((uint32_t)sector, buff) != 0)
            return RES_ERROR;
        sector++;
        buff += 512;
    }
    return RES_OK;
}

#if !FF_FS_READONLY
DRESULT disk_write(BYTE pdrv, const BYTE *buff, LBA_t sector, UINT count)
{
    if (pdrv != 0 || count == 0)
        return RES_PARERR;
    if (stat & STA_NOINIT)
        return RES_NOTRDY;
    if (stat & STA_PROTECT)
        return RES_WRPRT;

    while (count--) {
        if (sd_write_block((uint32_t)sector, buff) != 0)
            return RES_ERROR;
        sector++;
        buff += 512;
    }
    return RES_OK;
}
#endif

DRESULT disk_ioctl(BYTE pdrv, BYTE cmd, void *buff)
{
    (void)buff;

    if (pdrv != 0)
        return RES_PARERR;
    if (stat & STA_NOINIT)
        return RES_NOTRDY;

    switch (cmd) {
    case CTRL_SYNC:             /* flush pending writes */
#if !FF_FS_READONLY
        return sd_wait_ready() == 0 ? RES_OK : RES_ERROR;
#else
        return RES_OK;
#endif

    case GET_SECTOR_SIZE:       /* only used if FF_MAX_SS != FF_MIN_SS */
        *(WORD *)buff = 512;
        return RES_OK;

    case GET_BLOCK_SIZE:        /* erase block size in sectors; 1 = unknown */
        *(DWORD *)buff = 1;
        return RES_OK;

    /* GET_SECTOR_COUNT is only needed by f_mkfs/f_fdisk (read CSD to add). */
    default:
        return RES_PARERR;
    }
}