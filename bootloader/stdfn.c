#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>

void setled(char led_state) {
char * led = (char *)0xffffff00;
  led[0] = led_state;
}


int _write (int fd, char *buf, int count) {
  char * uart = (char *)0xffffff01;
  char * uart_status = (char *)0xffffff02;
  for(int i=0;i<count;i++) {
    uart[0] = buf[i];
    while((uart_status[0] & 1)== 1) {};
  }
  return count;
}

int _read (int fd, char *buf, int count) {
  char * uart_in = (char *)0xffffff03;
  char * uart_status = (char *)0xffffff02;
  int pos=0;
  while(pos<count){
    if((uart_status[0] & 2)== 2) {
      buf[pos]=uart_in[0];
    }
  }
  return count;
}

int _lseek(int fd, off_t offset, int whence) {
  return 0;
}

int _fstat (int file, struct stat *buf) {
  return  0;
}

int _close(int fd) {
  return 0;
}

int _isatty(int fd) {
  return 1;
}


pid_t _getpid() {
  return 23;
}

int _kill(pid_t pid, int sig){
  return 0;
}
