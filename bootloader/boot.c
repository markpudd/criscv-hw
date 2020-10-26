//
//  Super basic bootloader
//  This has been written quickly for testing
//
#include <sys/asm.h>
#include "stdfn.h"

#define STDFN_INC 1

char led_state=1;
char * led = (char *)0xffffff00;
char * uart = (char *)0xffffff01;
char * uart_status = (char *)0xffffff02;
char * uart_in = (char *)0xffffff03;

extern void syscall();

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
    sendchar(str[pos++]);
    while((uart_status[0] & 1)== 1) {};
  }
}


int load(  unsigned char * load_ram_base) {

  unsigned int len=0;

  unsigned char in=0;

  int blopck=0;
  int perc_count=0;
  int perc_top=0;
  // read length
  load_ram_base=  (unsigned char *)0x10000;


  //sendstring("|\e[32C|\e[33D");
  sendstring("|................................|\n ");


  for(int i=0;i<5;i++) {
      while((uart_status[0] & 2)!= 2) {};
      in = uart_in[0];
      len = len << 8;
      len = len +(  unsigned int)in;
  }
  perc_top = len >>5;
  led_state=led_state^0x08;
  setled();




  for(int i=0;i<len;i++) {
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
  int  start = ((int*)load_ram_base)[6];
  int (*boot_main)(void) = (int (*)())(start);
  return boot_main();
}

int main() {

  unsigned char * load_ram_base=  (unsigned char *)0x10000;

  void (*traps[16])();

  sendstring("CRISC-V Bootloader v0.1\n");
  if(STDFN_INC) {
    traps[11] =syscall;
    asm("csrw  mtvec, %0" :  : "r"(&traps));
    sendstring("Stdfn (v0.1) ECALL Available\n");
//    sendstring("UART Available\n");
//    sendstring("SPI, I2C Not Available\n");
  }


  led_state=3;
  setled();

  if(load(load_ram_base)) {
      sendstring("Load failure\n");
  } else {
      sendstring("Load complete\n");
  }


  sendstring("Starting\n");
  run(load_ram_base);
  sendstring("Finished\n");
  return 0;

}
