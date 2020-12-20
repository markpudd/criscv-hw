#include "stdfn.h"
#include <sys/asm.h>
#include <sys/time.h>

#include <machine/syscall.h>


int pid;
extern char * _end[]; 

char* file_dp;
int  fdp_offset;

int _write (int fd, char *buf, int count) {
  if(fd != 5) {
    char * uart = (char *)0xffffff01;
    char * uart_status = (char *)0xffffff02;
    for(int i=0;i<count;i++) {
      uart[0] = buf[i];
      while((uart_status[0] & 1)== 1) {};
    }
  } else {
    for(int i=0;i<count;i++) {
        file_dp[fdp_offset++]=buf[i];
      
    }
  }


  return count;
}

int _read (int fd, char *buf, int count) {
  if(fd != 5) {
    char * uart_in = (char *)0xffffff03;
    char * uart_status = (char *)0xffffff02;
    int pos=0;
    while(pos<count){
      if((uart_status[0] & 2)== 2) {
        buf[pos]=uart_in[0];
      }
    }
  } else {
    for(int i=0;i<count;i++) {
        buf[i]=file_dp[fdp_offset++];
    }
  }
  return count;
}

int
_open(const char *name, int flags, int mode)
{
  if(!strcmp("./test.bin"),name) {
    file_dp=  (unsigned char *)0xC00000;
    fdp_offset =0;
    return 5;
  }
  return NULL;
}

int _lseek(int fd, off_t offset, int whence) {
  if(fd == 5) {
    switch (whence) {
      case SEEK_SET:
        fdp_offset=offset;
        break;
      case SEEK_CUR:
        fdp_offset=fdp_offset+offset;
        break;
            
    } 
      return fdp_offset;
  }
  return 0;

}

int _fstat (int file, struct stat *buf) {
  return  0;
}

int _close(int fd) {
  return 0;
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
   return 1;
 }
 
int _brk(int incr) {
  int * bss_size = (int *)0x0;

  if(incr == 0)
    return _end+bss_size[0];
  else
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

void syscall() __attribute__ ((interrupt ("machine")));

void syscall() {
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