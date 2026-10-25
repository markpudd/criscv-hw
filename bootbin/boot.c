//
//  Super basic bootloader
//  This has been written quickly for testing
//
//  v0.4: SD card (FatFs) support merged in - ls/cd/pwd/cat/run/load/mount.
//        Programs are loaded from the card to PROG_BASE (0x10000) and run
//        through the same after_load() path as upload/rb.
//
//#include <sys/asm.h>
#include "stdfn.h"
#include <elf.h>
#include <string.h>
#include <stdlib.h>
#include "ymodem.h"
#include "ff.h"

#define STDFN_INC 1

struct FileHeader {
   char  type;
   char  name[20];
   uint32_t length;
} FileHeader;

#define LED (*(volatile unsigned char *)0xFFFFFF00)
#define UART (*(volatile unsigned char *)0xffffff01)
#define UART_STATUS (*(volatile unsigned char *)0xffffff02)
#define UART_IN (*(volatile unsigned char *)0xffffff03)

#define DEBUG_ADD1 (*(volatile int *)0x00003e00)
#define DEBUG_ADD2 (*(volatile int *)0x00003e04)

// Load regions (match the addresses used by load())
#define PROG_BASE ((unsigned char *)0x10000)
#define PROG_MAX  (0xC00000 - 0x10000)   // program must not run into the data region
#define DATA_BASE ((unsigned char *)0xD00000)
#define DATA_MAX  (0x100000)             // adjust to the size of your data RAM


char led_state=0;


extern void syscall();
extern int pid;
extern char _end[]; 
extern void stdfn_close_all(void);   // in stdfn.c - closes files a program left open
int ftype=0;

static FATFS sd_fs;
static int sd_mounted=0;



void setled() {
  LED = led_state;
}

// Now waits for the transmitter like sendstring() does, so the 'X' progress
// marks, put_hex() and cat output can't overrun the UART.
void sendchar(char c) {
  while((UART_STATUS & 0x01)== 1) {};
  UART = c;
}


  // We could use printf but want to keep bootloader code small
void sendstring(char * str) {
  int pos=0;
  while(str[pos] != 0) {
    sendchar(str[pos++]);
  }
}

void waitForStart() {
  char  in;
  char * start = "RVF";
  int st_pos=0;
  while(st_pos<3) {
      while((UART_STATUS & 0x02)!= 2) {};
      in = UART_IN;
      if(in == start[st_pos]) {
        st_pos++;
      } else
      {
        if(in == start[0]) 
          st_pos=1;
        else
          st_pos=0;
      }
      
  }
}

void readBytes(unsigned char * buf,int len) {
  for(int i=0;i<len;i++) {
      while((UART_STATUS & 0x02)!= 2) {};
      buf[i] = UART_IN;
  }
}
  struct FileHeader fileHeader;

int load() {

  char in;



  int perc_count=0;
  int perc_top=0;
  // read length
  unsigned char* load_ram_base=  (unsigned char *)0x10000;

sendstring("Waiting for file\n");


  waitForStart();
  //sendstring("Recieving file\n");
  led_state=led_state^0x08;
  setled();

  // Avoid struct alignment issues
  readBytes((unsigned char *)(&fileHeader.type),1);
  readBytes((unsigned char *)(fileHeader.name),20);
  readBytes((unsigned char *)(&fileHeader.length),4);

 // sendstring("Filename - ");
  //sendstring(fileHeader.name);
  //sendstring("\n");
  perc_top = fileHeader.length >>5;

  switch(fileHeader.type) {
    case 0:
      sendchar('p');
      break;
    case 1:                                
      load_ram_base=  (unsigned char *)0xC00000;
      sendchar('f');
      break;
    default:
      sendchar('?');
      break;
  }
  DEBUG_ADD1 =fileHeader.length+3;

  for(int i=0;i<fileHeader.length;i++) {
    while((UART_STATUS & 0x02)!= 2) {};
    in = UART_IN;
    load_ram_base[i]=in;
    perc_count++;
    if(perc_count == perc_top) {
      sendchar('X');
        perc_count=0;
    }
  }
  sendchar('\n');
  led_state=4;
  setled();
  sendstring(" recieved\n");
  return 0;
}


int run(unsigned char *load_ram_base, int argc, char **argv) {
  pid =2;
  int  start = ((int*)load_ram_base)[6];
  int (*boot_main)(int, char **) = (int (*)(int, char **))(uintptr_t)start;
  return boot_main(argc, argv);
}


 Elf32_Shdr * getBssHeader(unsigned char * load_ram_base) {
      Elf32_Ehdr * header = (Elf32_Ehdr *)load_ram_base;
      int e_shoff  = header->e_shoff;
      int e_shnum  =  header->e_shnum;  
      int e_shentsize = header->e_shentsize;
      int e_shstrndx = header->e_shstrndx;
      unsigned char * spnt = load_ram_base+e_shoff;
     
      Elf32_Off string_st = ((Elf32_Shdr *)((e_shstrndx*e_shentsize)+spnt))->sh_offset;

      for(int i=0;i<e_shnum;i++) {
          Elf32_Shdr * sh = (Elf32_Shdr *)spnt;
          char * name = (char*)(load_ram_base+string_st+(sh->sh_name));
          if(!strcmp(".bss",name)) {
              return sh;
          }
          spnt = spnt+e_shentsize;
      }
      return 0;
}
// Simple character input helpers for the interactive shell
char readchar() {
  while((UART_STATUS & 2) != 2) {};
  char c = UART_IN;
  if(c ==0)
     c='.';
  return c;
}

int readline(char *buf, int max) {
  int pos = 0;
  char c;
  while(pos < max-1) {
    c = readchar();
    if(c == '\r') break;
    if(c == '\n') break;
    if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
    buf[pos++] = c;
    sendchar(c);
  }
  buf[pos] = 0;
  sendstring("\n");
  return pos;
}

void byte_to_hex(unsigned char byte, char *output) {
  const char hex_chars[] = "0123456789abcdef";
  
  output[0] = hex_chars[(byte >> 4) & 0x0F]; // Get high 4 bits
  output[1] = hex_chars[byte & 0x0F];        // Get low 4 bits
  output[2] = ' ';                          // Null-terminate the string
  output[3] = '\0';                          // Null-terminate the string
}


// Common handling once a file is in RAM (used by upload, rb and SD run)
void after_load(int argc, char **argv) {
  char temp[16];
  char hex[4]; 
  unsigned char * load_ram_base= PROG_BASE;

  sendstring("Filename = ");
  sendstring(fileHeader.name);
  sendstring("\n");
  if(fileHeader.type==0) {
    // Sanity check: don't jump into something that isn't an ELF
    if(load_ram_base[0]!=0x7f || load_ram_base[1]!='E' ||
       load_ram_base[2]!='L'  || load_ram_base[3]!='F') {
      for (int i=0;i<15;i++) {
        for(int j=0;j<16;j++) {
          byte_to_hex(load_ram_base[(i*16)+j], hex);
          sendstring(hex);
        }
        sendstring("\n");
      }
      return;
    }
    Elf32_Shdr * bssHeader = getBssHeader(load_ram_base);
    if(bssHeader == 0) {
      sendstring("Error BSS header\n");
      return;
    }
    sendstring("File type program\n");
    itoa((int)(load_ram_base+bssHeader->sh_offset), temp, 16);
    sendstring("Setting heap to  = ");
    sendstring(temp);
    sendstring("\n");
    run(load_ram_base, argc, argv);
    stdfn_close_all();          // flush anything the program didn't close
    sendstring("Finished\n");
  } else {
    sendstring("File type data\n");
  }
}

static void put_hex(uint32_t v)
{
    for (int i = 28; i >= 0; i -= 4) {
        uint32_t d = (v >> i) & 0xf;
        sendchar(d < 10 ? '0' + d : 'a' + d - 10);
    }
}
int32_t mem_addr_test(uint32_t start, uint32_t end, int byte_stores)
{
    uint32_t a, v, errs = 0;
 
    for (a = start; a < end; a += 4) {
        if (byte_stores) {
            volatile uint8_t *b = (volatile uint8_t *)a;   /* little-endian */
            b[0] = a; b[1] = a >> 8; b[2] = a >> 16; b[3] = a >> 24;
        } else {
            *(volatile uint32_t *)a = a;
        }
    }
 
    for (a = start; a < end; a += 4) {
        v = *(volatile uint32_t *)a;
        if (v != a) {
            if (errs < 8) {
              sendstring("FAIL @");  (put_hex(a));
              sendstring(" got ");   (put_hex(v));
              sendstring(" xor ");   (put_hex(v ^ a));
              sendstring("\r\n");
            }
            errs++;
        }
    }
 
    sendstring(errs ? "errors: " : "PASS ");
     (put_hex(errs));
    sendstring("\r\n");
    return errs;
}

// ---------------------------------------------------------------------------
//  SD card / FatFs
// ---------------------------------------------------------------------------

static void send_fr(char *what, FRESULT fr) {
  char temp[12];
  sendstring(what);
  sendstring(": error ");
  itoa((int)fr, temp, 10);        // FRESULT number - see ff.h for meaning
  sendstring(temp);
  sendstring("\n");
}

static void sd_mount() {
  sendstring("Mounting.....\n");
  FRESULT fr = f_mount(&sd_fs, "", 1);
  sd_mounted = (fr == FR_OK);
  if(sd_mounted) sendstring("SD card mounted\n");
  else           send_fr("mount", fr);
}

static int sd_ready() {
  if(!sd_mounted) sendstring("No SD card mounted (try 'mount')\n");
  return sd_mounted;
}

void ls_cmd(char *path) {
  DIR dir;
  FILINFO fno;
  FRESULT fr;
  char temp[12];

  if(!sd_ready()) return;
  fr = f_opendir(&dir, path ? path : "");
  if(fr != FR_OK) { send_fr("ls", fr); return; }
  for(;;) {
    fr = f_readdir(&dir, &fno);
    if(fr != FR_OK) { send_fr("ls", fr); break; }
    if(fno.fname[0] == 0) break;              // end of directory
    if(fno.fattrib & AM_DIR) {
      sendstring("     <DIR> ");
    } else {
      itoa((int)fno.fsize, temp, 10);
      for(int n=strlen(temp); n<10; n++) sendchar(' ');
      sendstring(temp);
      sendchar(' ');
    }
    sendstring(fno.fname);
    sendstring("\n");
  }
  f_closedir(&dir);
}

void cd_cmd(char *dir) {
  if(!sd_ready()) return;
  FRESULT fr = f_chdir(dir);                  // needs FF_FS_RPATH >= 1
  if(fr != FR_OK) send_fr("cd", fr);
}

void pwd_cmd() {
#if FF_FS_RPATH >= 2
  char buf[64];
  if(!sd_ready()) return;
  FRESULT fr = f_getcwd(buf, sizeof(buf));
  if(fr != FR_OK) { send_fr("pwd", fr); return; }
  sendstring(buf);
  sendstring("\n");
#else
  sendstring("pwd: needs FF_FS_RPATH 2\n");
#endif
}

void cat_cmd(char *fname) {
  FIL f;
  UINT br;
  char buf[64];

  if(!sd_ready()) return;
  FRESULT fr = f_open(&f, fname, FA_READ);
  if(fr != FR_OK) { send_fr("cat", fr); return; }
  do {
    fr = f_read(&f, buf, sizeof(buf), &br);
    for(UINT i=0; i<br; i++) sendchar(buf[i]);
  } while(fr == FR_OK && br == sizeof(buf));
  if(fr != FR_OK) send_fr("cat", fr);
  f_close(&f);
  sendstring("\n");
}

// Read a whole file into RAM and fill in fileHeader the same way load()/rb do,
// so after_load() works unchanged. Returns 0 on success.
static int sd_load(char *fname, unsigned char *base, uint32_t max, char type) {
  FIL f;
  UINT br;
  uint32_t size, done=0;
  char temp[12];

  if(!sd_ready()) return -1;
  FRESULT fr = f_open(&f, fname, FA_READ);
  if(fr != FR_OK) { send_fr("open", fr); return -1; }

  size = (uint32_t)f_size(&f);
  if(size > max) {
    sendstring("File too big\n");
    f_close(&f);
    return -1;
  }

  // Read in 16KB chunks: still multi-sector reads straight into RAM,
  // but gives some progress feedback on larger files
  while(done < size) {
    uint32_t chunk = size - done;
    if(chunk > 0x4000) chunk = 0x4000;
    fr = f_read(&f, base + done, chunk, &br);
    if(fr != FR_OK || br != chunk) break;
    done += br;
    sendchar('X');
  }
  f_close(&f);
  sendstring("\n");
  if(done != size) { send_fr("read", fr); return -1; }

  strncpy(fileHeader.name, fname, sizeof(fileHeader.name)-1);
  fileHeader.name[sizeof(fileHeader.name)-1] = 0;
  fileHeader.type   = type;
  fileHeader.length = size;

  itoa((int)size, temp, 10);
  sendstring("Loaded ");
  sendstring(temp);
  sendstring(" bytes\n");
  return 0;
}

// run <file> : load an ELF from the card to PROG_BASE and run it
void run_cmd(char *fname, int argc, char **argv) {
  if(sd_load(fname, PROG_BASE, PROG_MAX, 0) == 0)
    after_load(argc, argv);
}

// load <file> : load a data file from the card to DATA_BASE
void load_cmd(char *fname) {
  if(sd_load(fname, DATA_BASE, DATA_MAX, 1) == 0)
    after_load(0, 0);
}

// ---------------------------------------------------------------------------

// Extracted upload loop from original main; called by the shell `upload` command
void upload_loop() {
  sendstring("Waiting....\n");
  if(load()) {
    sendstring("Load failure\n");
  } else {
    sendstring("Load complete\n");
    after_load(0, 0);
  }
}

void mt_cmd(char* args) {
  mem_addr_test(0x10000, 0x20000, 0);
  mem_addr_test(0x10000, 0x20000, 1);
}
// YMODEM upload: `rb` auto-detects (ELF -> program, else data), `rb p` / `rb d` force it
void rb_cmd(char *arg) {
  ym_file_t yf;
  char temp[16];
  int force = -1;
  if(arg && arg[0]=='p') force = YM_TYPE_PROG;
  if(arg && arg[0]=='d') force = YM_TYPE_DATA;

  sendstring("rb: start YMODEM send now\n");
  int r = ym_receive(PROG_BASE, PROG_MAX, DATA_BASE, DATA_MAX, force, &yf);
  led_state = 4;
  setled();

  // let the host terminal drop out of transfer mode before we print
  for(volatile int d=0; d<200000; d++) {};
  sendstring("\n");

  if(r < 0) {
    if(r == YM_ERR_CANCEL)       sendstring("rb: cancelled\n");
    else if(r == YM_ERR_TIMEOUT) sendstring("rb: timed out waiting for sender\n");
    else if(r == YM_ERR_TOOBIG)  sendstring("rb: file too big\n");
    else                         sendstring("rb: too many errors\n");
    return;
  }

  // Reuse the existing header so the rest of the bootloader is unchanged
  strcpy(fileHeader.name, yf.name);
  fileHeader.type   = yf.type;
  fileHeader.length = yf.length;

  itoa((int)yf.length, temp, 10);
  sendstring("Load complete, ");
  sendstring(temp);
  sendstring(" bytes\n");
  after_load(0, 0);
}

void shell() {
  char buf[128];
  char *argv[17];
  sendstring("CRISC-V Bootloader v0.4 - RV32I (YMODEM, SD)\n");

  while(1) {
    sendstring("> ");
    readline(buf, sizeof(buf));
    int argc = 0;
    char *arg = strtok(buf, " \t");
    if(!arg) continue;
    argv[argc++] = arg;
    while((arg = strtok(0, " \t")) != 0) {
      if(argc == 16) {
        sendstring("Too many arguments (maximum 16)\n");
        argc = -1;
        break;
      }
      argv[argc++] = arg;
    }
    if(argc < 0) continue;
    argv[argc] = 0;
    char *cmd = argv[0];
    if(!strcmp(cmd, "ls")) {
      ls_cmd(argc > 1 ? argv[1] : 0);
    } else if(!strcmp(cmd, "cd")) {
      if(argc > 1) cd_cmd(argv[1]); else sendstring("cd: missing argument\n");
    } else if(!strcmp(cmd, "pwd")) {
      pwd_cmd();
    } else if(!strcmp(cmd, "cat")) {
      if(argc > 1) cat_cmd(argv[1]); else sendstring("cat: missing filename\n");
    } else if(!strcmp(cmd, "run")) {
      if(argc > 1) run_cmd(argv[1], argc - 1, &argv[1]);
      else sendstring("run: missing filename\n");
    } else if(!strcmp(cmd, "load")) {
      if(argc > 1) load_cmd(argv[1]); else sendstring("load: missing filename\n");
    } else if(!strcmp(cmd, "mount")) {
      sd_mount();
    } else if(!strcmp(cmd, "upload")) {
      upload_loop();
    } else if(!strcmp(cmd, "rb")) {
      rb_cmd(argc > 1 ? argv[1] : 0);
    } else if(!strcmp(cmd, "mt")) {
      mt_cmd(argc > 1 ? argv[1] : 0);
    } else if(!strcmp(cmd, "help")) {
      sendstring("Commands: ls [dir] cd pwd cat run <program> [args...] load mount upload rb [p|d] mt help\n");
    } else {
      run_cmd(cmd, argc, argv);
    }
  }
}


int sys_exit() {
	sendstring("\n");
	shell();
}

void setLed3() {
  LED=4;
}
int main() {
 // char temp[16];
 //LED = 1;

 //UART ='A';

 DEBUG_ADD2=0x55FF;
 DEBUG_ADD1=0x77EE;
 //unsigned char * load_ram_base= (unsigned char *)0x10000;
  pid=0;
 // int* bss_size =0x0;
 // void (*traps[16])();
  
  for(int i=0;i<16;i++) {
    for(int x=0;x<62500;x++) {
      DEBUG_ADD1 =i;
      DEBUG_ADD2= x;
    }
    DEBUG_ADD2=0x55FF;
    DEBUG_ADD1=0x77EE;

    LED=i;
    //setled();
  }

  LED=2;
  //setled();
  //setLed3();
 // UART ='C';
 // while((UART_STATUS & 0x01)== 1) {};
 // UART ='D';
 LED=3;
 //   ___ ___ ___ ___ ___     __   __
//  / __| _ \_ _/ __/ __|____\ \ / /   RV32I soft-core
// | (__|   /| |\__ \ (_|_____\ V /    Cyclone FPGA
//  \___|_|_\___|___/\___|     \_/
//====================================================
sendstring("  ___ ___ ___ ___ ___     __   __\n");
sendstring(" / __| _ \\_ _/ __/ __|____\\ \\ / /   RV32I \n");
sendstring("| (__|   /| |\\__ \\ (_|_____\\ V /    0.1\n");
sendstring(" \\___|_|_\\___|___/\\___|     \\_/ \n");

  
  if(STDFN_INC) {
    //traps[11] =syscall;
    asm("csrw  mtvec, %0" :  : "r"(&syscall));
    sendstring("Stdfn (v0.1) ECALL Available\n");
  }

  sd_mount();       // not fatal if it fails - UART upload still works

  shell();

  return 0;
}