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

int hextobin(char * c, int len) {
      int ret =0;
      for(int i=0;i<len;i++) {
        ret = ret << 4;
        char c1 = c[i];
        if(c1 >='0' && c1 <='9')
          ret = ret + (c1-'0') ;
        if(c1 >='A' && c1 <='F')
          ret = ret + ((c1-'A')+10);
      }
      return ret;
}
int store(char* st,char* ram ) {
  if(st[0]  != ':')
    return -1;

  int nobyte= hextobin(st+1,2);
  int address= hextobin(st+3,4);
  int type= hextobin(st+7,2);
  if(type==1)
    return 1;
  for(int i =0;i<nobyte;i++) {
    char byte = hextobin(st+(i*2)+9, 2);
    ram[(address*nobyte)+i] = byte;
  }
  return 0;
}


int main() {
  char * uart_status = (char *)0xffffff02;
  char * uart_in = (char *)0xffffff03;
  char * sd_ram_base =  (char *)0x10000;
  //char sd_ram_base[1000];
  char inputSt[128];
  char in=0;
  int r_offset=0;
  int end = 0;
  int pos=0;
  led_state=3;

  setled();
  while(end == 0) {
    while(in != 0x0a) {
      if((uart_status[0] & 2)== 2) {
        in = uart_in[0];
        inputSt[pos++]=in;

      }
    }
    if(pos == 16)
      sendchar('x');
    else
          sendchar('m');
    while((uart_status[0] & 1)== 1) {};
    led_state=led_state^0x08;
    end = store(inputSt, sd_ram_base);
    r_offset +=2;
    led_state=led_state^1;
    setled();
    pos=0;
    in=0;
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
