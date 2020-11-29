//
//  Super basic bootloader
//  This has been written quickly for testing
//
#include <sys/asm.h>
#include "stdfn.h"
#include <elf.h>
#include <string.h>
#include <stdlib.h>

#define STDFN_INC 1

struct FileHeader {
   char  type;
   char  name[20];
   uint32_t length;
} FileHeader;


char led_state=1;
char * led = (char *)0xffffff00;
char * uart = (char *)0xffffff01;
char * uart_status = (char *)0xffffff02;
char * uart_in = (char *)0xffffff03;

extern void syscall();
extern int pid;
extern char _end[]; 
int ftype=0;


void setled() {
  led[0] = led_state;
}

void sendchar(char c) {
  uart[0] = c;
}


  // We could use printf but want to keep bootloader code small
void sendstring(char * str) {
  int pos=0;
  while(str[pos] != 0) {
        while((uart_status[0] & 1)== 1) {};
    sendchar(str[pos++]);

  }
}

void waitForStart() {
  char  in;
  char * start = "RVF";
  int st_pos=0;
  while(st_pos<3) {
      while((uart_status[0] & 2)!= 2) {};
      in = uart_in[0];
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
      while((uart_status[0] & 2)!= 2) {};
      buf[i] = uart_in[0];
  }
}
  struct FileHeader fileHeader;

int load() {

  char in;



  int perc_count=0;
  int perc_top=0;
  // read length
  unsigned char* load_ram_base=  (unsigned char *)0x10000;

sendstring("|................................|\n");


  waitForStart();
  
  led_state=led_state^0x08;
  setled();

  // Avoid struct alignment issues
  readBytes((unsigned char *)(&fileHeader.type),1);
  readBytes((unsigned char *)(&fileHeader.name),20);
  readBytes((unsigned char *)(&fileHeader.length),4);
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

  for(int i=0;i<fileHeader.length;i++) {
    while((uart_status[0] & 2)!= 2) {};
    in = uart_in[0];
    load_ram_base[i]=in;
    perc_count++;
    if(perc_count == perc_top) {
      sendchar('X');
        perc_count=0;
    }
  }
  while((uart_status[0] & 1)== 1) {};
  sendchar('\n');
  while((uart_status[0] & 1)== 1) {};
  led_state=4;
  setled();
  return 0;
}

int run(  unsigned char * load_ram_base) {
  pid =2;
  int  start = ((int*)load_ram_base)[6];
  int (*boot_main)(void) = (int (*)())(start);
  return boot_main();
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

int main() {
  char temp[16];

 unsigned char * load_ram_base= (unsigned char *)0x10000;
  pid=1;
  int* bss_size =0x0;
  void (*traps[16])();

  sendstring("CRISC-V Bootloader v0.1\n");
  if(STDFN_INC) {
    traps[11] =syscall;
    asm("csrw  mtvec, %0" :  : "r"(&traps));
    sendstring("Stdfn (v0.1) ECALL Available\n");
  }


  led_state=3;
  setled();


  while(1) {
    sendstring("Waiting....\n");
    if(load()) {
        sendstring("Load failure\n");
    } else {
        sendstring("Load complete\n");
        sendstring("Filename = ");
        sendstring(fileHeader.name);
        sendstring("\n");
        if(fileHeader.type==0) {
          Elf32_Shdr * bssHeader = getBssHeader(load_ram_base);
          bss_size[0] = bssHeader->sh_size;
          sendstring("File type program\n");
          itoa((int)(load_ram_base+bssHeader->sh_offset), temp, 16);
          sendstring("Setting heap to  = ");
          sendstring(temp);
          sendstring("\n");
          run(load_ram_base);
          sendstring("Finished\n");
        } else
        {
          sendstring("File type data\n");
        }
     }
  }
  return 0;

}



