
#ifndef __STDFN_H
#define __STDFN_H

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>


int _write (int fd, char *buf, int count);
int _read (int fd, char *buf, int count) ;
int _lseek(int fd, off_t offset, int whence);
int _fstat (int file, struct stat *buf) ;
int _close(int fd);
int _isatty(int fd) ;
pid_t _getpid() ;
int _kill(pid_t pid, int sig);


#endif
