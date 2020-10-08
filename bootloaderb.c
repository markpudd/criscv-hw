//
//  Super basic bootloader
//  This has been written quickly for testing
//

char led_state=1;

void setled() {
char * led = (char *)0xffffff00;

led[0] = led_state;
}

void sendchar(char c) {
char * uart = (char *)0xffffff01;

uart[0] = c;
}

int main() {
  char * uart_status = (char *)0xffffff02;
  char * uart_in = (char *)0xffffff03;
  unsigned char * sd_ram_base =  (unsigned char *)0x10000;
  //char sd_ram_base[1000];
  unsigned char in=0;
//  unsigned char inp[4];
  led_state=3;
  unsigned int len=0;

  setled();
  // read length
  for(int i=0;i<5;i++) {
      while((uart_status[0] & 2)!= 2) {};
      in = uart_in[0];
      len = len << 8;
      len = len +(  unsigned int)in;
  }

  led_state=led_state^0x08;
  setled();

  for(int i=0;i<len;i++) {
    while((uart_status[0] & 2)!= 2) {};
    in = uart_in[0];
    sd_ram_base[i]=in;
  }

  sendchar('e');
  while((uart_status[0] & 1)== 1) {};
  led_state=4;
  setled();

  int  start = ((int*)sd_ram_base)[6];
  void (*boot_main)(void) = (void (*)())(start);
  boot_main();

  sendchar('f');
  while(1){};
  return 0;

}
