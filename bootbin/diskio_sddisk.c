#include "ff.h"
#include "diskio.h"
#include "sddisk.h"

static DSTATUS drive_status = STA_NOINIT;

DSTATUS disk_initialize(BYTE pdrv)
{
	if (pdrv != 0) {
		return STA_NOINIT;
	}

	drive_status = sddisk_init() == 0 ? 0 : STA_NOINIT;
	return drive_status;
}

DSTATUS disk_status(BYTE pdrv)
{
	return pdrv == 0 ? drive_status : STA_NOINIT;
}

DRESULT disk_read(BYTE pdrv, BYTE *buff, LBA_t sector, UINT count)
{
	if (pdrv != 0 || (drive_status & STA_NOINIT)) {
		return RES_NOTRDY;
	}
	if (buff == 0 || count == 0 || sector > UINT32_MAX - (count - 1)) {
		return RES_PARERR;
	}

	for (UINT index = 0; index < count; index++) {
		if (sddisk_read_block((uint32_t)sector + index, buff + index * 512) != 0) {
			return RES_ERROR;
		}
	}
	return RES_OK;
}

DRESULT disk_write(BYTE pdrv, const BYTE *buff, LBA_t sector, UINT count)
{
	(void)buff;
	(void)sector;
	(void)count;
	return pdrv == 0 && !(drive_status & STA_NOINIT) ? RES_WRPRT : RES_NOTRDY;
}

DRESULT disk_ioctl(BYTE pdrv, BYTE cmd, void *buff)
{
	if (pdrv != 0) {
		return RES_PARERR;
	}
	if (drive_status & STA_NOINIT) {
		return RES_NOTRDY;
	}

	switch (cmd) {
	case CTRL_SYNC:
		return RES_OK;
	case GET_SECTOR_SIZE:
		if (buff == 0) return RES_PARERR;
		*(WORD *)buff = 512;
		return RES_OK;
	case GET_BLOCK_SIZE:
		if (buff == 0) return RES_PARERR;
		*(DWORD *)buff = 1;
		return RES_OK;
	default:
		return RES_PARERR;
	}
}