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

#define read_csr(reg) ({ unsigned long __v; \
  asm volatile ("csrr %0, " #reg : "=r"(__v)); __v; })
#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"(val))

#define CAUSE_MISALIGNED_FETCH  0
#define CAUSE_ILLEGAL_INSN      2
#define CAUSE_MISALIGNED_LOAD   4
#define CAUSE_MISALIGNED_STORE  6
#define CAUSE_ECALL_M           11


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
 
 #define HEAP_LIMIT  0x01F00000          // below top of SDRAM, adjust

 static uintptr_t cur_brk;
 
 int _brk(int addr)
 {
     volatile const uint32_t *bss_size = (volatile const uint32_t *)0x0;
 
     if (cur_brk == 0)
         cur_brk = ((uintptr_t)(_end + bss_size[0]) + 7) & ~(uintptr_t)7;
 
     if (addr == 0)
         return (int)cur_brk;
 
     if ((uintptr_t)addr > HEAP_LIMIT || (uintptr_t)addr < cur_brk)
         return (int)cur_brk;            // refuse: sbrk sees != requested
 
     cur_brk = (uintptr_t)addr;
     return (int)cur_brk;
 }

 int _gettimeofday(struct timeval *tv, struct timezone *tz) {
  uint32_t hi, lo, hi2;

  // re-read if mcycle wrapped between the two halves
  do {
    asm volatile ("csrr %0, mcycleh" : "=r"(hi));
    asm volatile ("csrr %0, mcycle"  : "=r"(lo));
    asm volatile ("csrr %0, mcycleh" : "=r"(hi2));
  } while (hi != hi2);

  uint64_t us = (((uint64_t)hi << 32) | lo) / 50;   // 50 MHz cycles -> microseconds
  tv->tv_sec  = us / 1000000;
  tv->tv_usec = us % 1000000;
  return 0;
}

static void put_hex(unsigned long v) {
  for(int i = 28; i >= 0; i -= 4) {
    UART = "0123456789abcdef"[(v >> i) & 0xF];
    while((UART_STATUS & 0x01) == 1) {};
  }
}


// Non-ECALL trap: report and halt.  Returning would mret back onto the
// faulting instruction and trap again forever.
void trap_fault(unsigned long mcause, unsigned long mepc, unsigned long mtval) {
  LED = 0xFF;
  if(mcause == CAUSE_MISALIGNED_LOAD)
    UART = '*';
  else if(mcause == CAUSE_MISALIGNED_STORE)

 UART = '#';
  else
    UART = '!';
  while((UART_STATUS & 0x01) == 1) {};   // let the character go out
  put_hex(mepc);
  for(;;) {};
}

//-----------------------------------------------------------------------------
// Trap entry.
//
// mtvec points at `syscall` (same symbol as before, so the existing mtvec
// setup doesn't change).  It is now a small asm stub instead of an
// interrupt("machine") C function:
//
//  - saves the caller-saved registers (ra, t0-t6, a0-a7) into a frame on the
//    stack at FIXED offsets, so the C side can read the syscall arguments and
//    write the result into the saved a0 - no guessing at GCC's frame layout
//  - calls syscall_c(frame) as an ordinary C function (s0-s11 are preserved
//    by syscall_c itself under the normal ABI)
//  - restores everything, including the updated a0, and returns with mret
//
// ECALL return address: this core saves mepc = pc+4 on ECALL, so no
// mepc += 4 here.  If the RTL moves to the spec convention (mepc = pc of
// the ecall), add  write_csr(mepc, read_csr(mepc) + 4);  in syscall_c.
//-----------------------------------------------------------------------------
typedef struct {
  uint32_t ra, t0, t1, t2;
  uint32_t a0, a1, a2, a3, a4, a5, a6, a7;
  uint32_t t3, t4, t5, t6;
} trap_frame;

void syscall(void);              // the asm entry point below - set mtvec to this

__asm__(
"   .pushsection .text\n"
"   .balign 4\n"
"   .globl syscall\n"
"   .type  syscall, @function\n"
"syscall:\n"
"   addi sp, sp, -64\n"
"   sw ra,  0(sp)\n"
"   sw t0,  4(sp)\n"
"   sw t1,  8(sp)\n"
"   sw t2, 12(sp)\n"
"   sw a0, 16(sp)\n"
"   sw a1, 20(sp)\n"
"   sw a2, 24(sp)\n"
"   sw a3, 28(sp)\n"
"   sw a4, 32(sp)\n"
"   sw a5, 36(sp)\n"
"   sw a6, 40(sp)\n"
"   sw a7, 44(sp)\n"
"   sw t3, 48(sp)\n"
"   sw t4, 52(sp)\n"
"   sw t5, 56(sp)\n"
"   sw t6, 60(sp)\n"
"   mv a0, sp\n"
"   call syscall_c\n"
"   lw ra,  0(sp)\n"
"   lw t0,  4(sp)\n"
"   lw t1,  8(sp)\n"
"   lw t2, 12(sp)\n"
"   lw a0, 16(sp)\n"
"   lw a1, 20(sp)\n"
"   lw a2, 24(sp)\n"
"   lw a3, 28(sp)\n"
"   lw a4, 32(sp)\n"
"   lw a5, 36(sp)\n"
"   lw a6, 40(sp)\n"
"   lw a7, 44(sp)\n"
"   lw t3, 48(sp)\n"
"   lw t4, 52(sp)\n"
"   lw t5, 56(sp)\n"
"   lw t6, 60(sp)\n"
"   addi sp, sp, 64\n"
"   mret\n"
"   .size syscall, .-syscall\n"
"   .popsection\n"
);

void syscall_c(trap_frame *f) {
  unsigned long mcause = read_csr(mcause);

  if (mcause != CAUSE_ECALL_M) {
    uint32_t *r = (uint32_t *)f;
    for (int i = 0; i < 16; i++) { put_hex(r[i]); UART = ' '; }

    trap_fault(mcause, read_csr(mepc), 0);   // does not return
  }

  int a0 = f->a0, a1 = f->a1, a2 = f->a2, a3 = f->a3;
  int ret;

  switch (f->a7) {
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

  f->a0 = (uint32_t)ret;          // restored into a0 by the stub before mret
}