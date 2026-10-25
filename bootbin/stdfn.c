#include "stdfn.h"
//#include <sys/asm.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#include <machine/syscall.h>

#include "ff.h"


int pid;
//extern char * _end[]; 
extern char _end[];


extern int sys_exit();

// fd 0-2 are the UART, fd 3.. map onto FatFs files
#define FD_FIRST  3
#define FD_MAX    4          // simultaneously open files (each FIL has a 512B buffer)

static FIL  fd_fil[FD_MAX];
static char fd_used[FD_MAX];


#define LED (*(volatile unsigned char *)0xFFFFFF00)
#define UART (*(volatile unsigned char *)0xffffff01)
#define UART_STATUS (*(volatile unsigned char *)0xffffff02)
#define UART_IN (*(volatile unsigned char *)0xffffff03)


static FIL * fd_to_fil(int fd) {
  int i = fd - FD_FIRST;
  if(i < 0 || i >= FD_MAX || !fd_used[i])
    return 0;
  return &fd_fil[i];
}

// Negative errno is returned through a0; libgloss turns it into errno / -1
static int fr_to_err(FRESULT fr) {
  switch(fr) {
    case FR_NO_FILE:
    case FR_NO_PATH:
    case FR_INVALID_NAME:        return -ENOENT;
    case FR_EXIST:               return -EEXIST;
    case FR_DENIED:
    case FR_WRITE_PROTECTED:     return -EACCES;
    case FR_TOO_MANY_OPEN_FILES: return -EMFILE;
    default:                     return -EIO;
  }
}

// Called by the bootloader when a program returns, so unflushed writes
// reach the card and the fd slots are free for the next program
void stdfn_close_all(void) {
  for(int i=0;i<FD_MAX;i++) {
    if(fd_used[i]) {
      f_close(&fd_fil[i]);
      fd_used[i]=0;
    }
  }
}


int _write (int fd, char *buf, int count) {
  LED=7;
  if(fd < FD_FIRST) {
    for(int i=0;i<count;i++) {
      UART = buf[i];
      while((UART_STATUS & 0x01)== 1) {};
    }
    return count;
  }
#if !FF_FS_READONLY
  FIL *fp = fd_to_fil(fd);
  UINT bw;
  if(!fp) return -EBADF;
  FRESULT fr = f_write(fp, buf, count, &bw);
  return fr == FR_OK ? (int)bw : fr_to_err(fr);
#else
  return -EACCES;
#endif
}

int _read (int fd, char *buf, int count) {
  if(fd < FD_FIRST) {
    int pos=0;
    while(pos<count){
      while((UART_STATUS & 0x02)!= 2) {};
      buf[pos] = UART_IN;
      // return a line at a time, otherwise stdin blocks until the
      // whole stdio buffer (1KB) has been typed
      if(buf[pos++] == '\r' || buf[pos-1] == '\n') break;
    }
    return pos;
  }
  FIL *fp = fd_to_fil(fd);
  UINT br;
  if(!fp) return -EBADF;
  FRESULT fr = f_read(fp, buf, count, &br);
  return fr == FR_OK ? (int)br : fr_to_err(fr);
}

int
_open(const char *name, int flags, int mode)
{
  BYTE fmode;
  int i;
  FRESULT fr;

  for(i=0;i<FD_MAX;i++)
    if(!fd_used[i]) break;
  if(i == FD_MAX) return -EMFILE;

  switch(flags & O_ACCMODE) {
    case O_WRONLY: fmode = FA_WRITE;           break;
    case O_RDWR:   fmode = FA_READ | FA_WRITE; break;
    default:       fmode = FA_READ;            break;
  }
  if(flags & O_CREAT) {
    if(flags & O_EXCL)       fmode |= FA_CREATE_NEW;
    else if(flags & O_TRUNC) fmode |= FA_CREATE_ALWAYS;
    else                     fmode |= FA_OPEN_ALWAYS;
  }

  fr = f_open(&fd_fil[i], name, fmode);
  if(fr != FR_OK) return fr_to_err(fr);

#if !FF_FS_READONLY
  // O_TRUNC without O_CREAT: file must already exist, then gets emptied
  if((flags & O_TRUNC) && !(flags & O_CREAT) && (fmode & FA_WRITE))
    f_truncate(&fd_fil[i]);
#endif
  // Approximation of O_APPEND: start at the end (fine for single-writer use)
  if(flags & O_APPEND)
    f_lseek(&fd_fil[i], f_size(&fd_fil[i]));

  fd_used[i] = 1;
  return i + FD_FIRST;
}

int _lseek(int fd, off_t offset, int whence) {
  FIL *fp = fd_to_fil(fd);
  long long pos;
  if(!fp) return fd < FD_FIRST ? 0 : -EBADF;
  switch (whence) {
    case SEEK_SET: pos = offset;                 break;
    case SEEK_CUR: pos = f_tell(fp) + offset;    break;
    case SEEK_END: pos = f_size(fp) + offset;    break;
    default:       return -EINVAL;
  }
  if(pos < 0) return -EINVAL;
  FRESULT fr = f_lseek(fp, (FSIZE_t)pos);
  return fr == FR_OK ? (int)f_tell(fp) : fr_to_err(fr);
}

int _fstat (int file, struct stat *buf) {
  FIL *fp = fd_to_fil(file);
  memset(buf, 0, sizeof(*buf));
  if(file < FD_FIRST) {
    buf->st_mode = S_IFCHR;
    return 0;
  }
  if(!fp) return -EBADF;
  buf->st_mode = S_IFREG;
  buf->st_size = f_size(fp);
  return 0;
}

int _close(int fd) {
  FIL *fp = fd_to_fil(fd);
  if(!fp) return fd < FD_FIRST ? 0 : -EBADF;
  FRESULT fr = f_close(fp);
  fd_used[fd - FD_FIRST] = 0;
  return fr == FR_OK ? 0 : fr_to_err(fr);
}

pid_t _getpid() {
  return pid;
}

int _kill(pid_t pid, int sig){
  return 0;
}
/*
int _sbrk(int incr) {
  int *  heap_end = (int*) 0x00000000;
  int prev_end = heap_end[0];
  heap_end[0]=heap_end[0]+incr;
  return prev_end;
}
*/


 int _isatty(int fd){
   return fd < FD_FIRST;     // files get full buffering, console line buffering
 }
 
 int _brk(int incr)
 {
     volatile const uint32_t *bss_size = (volatile const uint32_t *)0x0;
 
     if (incr == 0)
         return (int)(uintptr_t)(_end + bss_size[0]);
 
     return incr;
 }

int _gettimeofday(struct timeval *tv, struct timezone *tz) {
  int mcycle;
  int mcycleh;
  asm("CSRRSI %0, mcycle,0" : "=r"(mcycle) : ); 
  asm("CSRRSI %0, mcycleh,0" : "=r"(mcycleh) : ); 

  // time in 50Mhz chyles
  long long time = mcycleh;
  time = ((long long)time) << 32;
  time = time |mcycle;

  long long total_ms = time/50;
  tv->tv_sec = total_ms/1000000;
  tv->tv_usec= total_ms%1000000;
  return 0;
}

//void syscall() __attribute__ ((interrupt ("machine")));
__attribute__((interrupt("machine"), aligned(4)))
void syscall(void) {
  int a0,a1,a2,a3,a4,a5,a7;
  int ret;
  // These are on stack so lets get them from there
  // so they don't get trashed
  asm("lw %0, 60(sp)" : "=r"(a7) : );
  asm("lw %0, 88(sp)" : "=r"(a0) : );
  asm("lw %0, 84(sp)" : "=r"(a1) : );
  asm("lw %0, 80(sp)" : "=r"(a2) : );
  asm("lw %0, 76(sp)" : "=r"(a3) : );
  asm("lw %0, 72(sp)" : "=r"(a4) : );
  asm("lw %0, 68(sp)" : "=r"(a5) : );
;


  switch (a7) {
    case SYS_write:
      ret=_write (a0, (char *)a1, a2);
       break;
    case SYS_read:
      ret=_read (a0, (char *)a1, a2);
       break;
    case SYS_lseek:
      ret=_lseek(a0, (off_t)a1 ,a2);
       break;
    case SYS_fstat:
      ret=_fstat (a0, (struct stat *)a1);
       break;
    case SYS_close:
      ret=_close(a0);
       break;
    case SYS_getgid:
      ret=_getpid();
       break;
     case SYS_kill:
       ret=_kill((pid_t)a0,a1);
       break;
    case SYS_open:
      ret=_open((char *)a0, a1,a2);
      break;
    case SYS_exit:
        ret = sys_exit();
      break;
#ifdef SYS_openat
    case SYS_openat:               // newer libgloss: openat(AT_FDCWD, name, flags, mode)
      ret=_open((char *)a1, a2,a3);
      break;
#endif
    case SYS_gettimeofday:
      ret=_gettimeofday((struct timeval *)a0,(struct timezone *) a1);
      break;
      
       case SYS_brk:
         ret=_brk(a0);
         break;
      default:
        ret=0;
        break;
     }

    asm("sw  %0, 88(sp)" :  : "r"(ret));
}