
boot:     file format elf32-littleriscv


Disassembly of section .text:

00000054 <exit>:
  54:	ff010113          	addi	sp,sp,-16
  58:	00812423          	sw	s0,8(sp)
  5c:	00112623          	sw	ra,12(sp)
  60:	00000793          	li	a5,0
  64:	00050413          	mv	s0,a0
  68:	00078863          	beqz	a5,78 <exit+0x24>
  6c:	00000593          	li	a1,0
  70:	00000097          	auipc	ra,0x0
  74:	000000e7          	jalr	zero # 0 <exit-0x54>
  78:	8601a503          	lw	a0,-1952(gp) # 1aac <_global_impure_ptr>
  7c:	02852783          	lw	a5,40(a0)
  80:	00078463          	beqz	a5,88 <exit+0x34>
  84:	000780e7          	jalr	a5
  88:	00040513          	mv	a0,s0
  8c:	0b5000ef          	jal	ra,940 <_exit>

00000090 <_start>:
  90:	00002197          	auipc	gp,0x2
  94:	1bc18193          	addi	gp,gp,444 # 224c <__global_pointer$>
  98:	88018513          	addi	a0,gp,-1920 # 1acc <completed.1>
  9c:	89c18613          	addi	a2,gp,-1892 # 1ae8 <__BSS_END__>
  a0:	40a60633          	sub	a2,a2,a0
  a4:	00000593          	li	a1,0
  a8:	07d000ef          	jal	ra,924 <memset>
  ac:	00000513          	li	a0,0
  b0:	00050863          	beqz	a0,c0 <_start+0x30>
  b4:	00000513          	li	a0,0
  b8:	00000097          	auipc	ra,0x0
  bc:	000000e7          	jalr	zero # 0 <exit-0x54>
  c0:	7c8000ef          	jal	ra,888 <__libc_init_array>
  c4:	00012503          	lw	a0,0(sp)
  c8:	00410593          	addi	a1,sp,4
  cc:	00000613          	li	a2,0
  d0:	318000ef          	jal	ra,3e8 <main>
  d4:	f81ff06f          	j	54 <exit>

000000d8 <__do_global_dtors_aux>:
  d8:	8801c703          	lbu	a4,-1920(gp) # 1acc <completed.1>
  dc:	04071263          	bnez	a4,120 <__do_global_dtors_aux+0x48>
  e0:	ff010113          	addi	sp,sp,-16
  e4:	00812423          	sw	s0,8(sp)
  e8:	00078413          	mv	s0,a5
  ec:	00112623          	sw	ra,12(sp)
  f0:	00000793          	li	a5,0
  f4:	00078a63          	beqz	a5,108 <__do_global_dtors_aux+0x30>
  f8:	00002537          	lui	a0,0x2
  fc:	a4050513          	addi	a0,a0,-1472 # 1a40 <__FRAME_END__>
 100:	00000097          	auipc	ra,0x0
 104:	000000e7          	jalr	zero # 0 <exit-0x54>
 108:	00100793          	li	a5,1
 10c:	00c12083          	lw	ra,12(sp)
 110:	88f18023          	sb	a5,-1920(gp) # 1acc <completed.1>
 114:	00812403          	lw	s0,8(sp)
 118:	01010113          	addi	sp,sp,16
 11c:	00008067          	ret
 120:	00008067          	ret

00000124 <frame_dummy>:
 124:	00000793          	li	a5,0
 128:	00078c63          	beqz	a5,140 <frame_dummy+0x1c>
 12c:	00002537          	lui	a0,0x2
 130:	88418593          	addi	a1,gp,-1916 # 1ad0 <object.0>
 134:	a4050513          	addi	a0,a0,-1472 # 1a40 <__FRAME_END__>
 138:	00000317          	auipc	t1,0x0
 13c:	00000067          	jr	zero # 0 <exit-0x54>
 140:	00008067          	ret

00000144 <setled>:
char * uart_status = (char *)0xffffff02;
char * uart_in = (char *)0xffffff03;

extern void syscall();

void setled() {
 144:	ff010113          	addi	sp,sp,-16
 148:	00812623          	sw	s0,12(sp)
 14c:	01010413          	addi	s0,sp,16


led[0] = led_state;
 150:	86c1a783          	lw	a5,-1940(gp) # 1ab8 <led>
 154:	8681c703          	lbu	a4,-1944(gp) # 1ab4 <led_state>
 158:	00e78023          	sb	a4,0(a5)
}
 15c:	00000013          	nop
 160:	00c12403          	lw	s0,12(sp)
 164:	01010113          	addi	sp,sp,16
 168:	00008067          	ret

0000016c <sendchar>:

void sendchar(char c) {
 16c:	fe010113          	addi	sp,sp,-32
 170:	00812e23          	sw	s0,28(sp)
 174:	02010413          	addi	s0,sp,32
 178:	00050793          	mv	a5,a0
 17c:	fef407a3          	sb	a5,-17(s0)

uart[0] = c;
 180:	8701a783          	lw	a5,-1936(gp) # 1abc <uart>
 184:	fef44703          	lbu	a4,-17(s0)
 188:	00e78023          	sb	a4,0(a5)
}
 18c:	00000013          	nop
 190:	01c12403          	lw	s0,28(sp)
 194:	02010113          	addi	sp,sp,32
 198:	00008067          	ret

0000019c <sendstring>:

  // We could use printf but want to keep bootloader code small
void sendstring(char * str) {
 19c:	fd010113          	addi	sp,sp,-48
 1a0:	02112623          	sw	ra,44(sp)
 1a4:	02812423          	sw	s0,40(sp)
 1a8:	03010413          	addi	s0,sp,48
 1ac:	fca42e23          	sw	a0,-36(s0)
  int pos=0;
 1b0:	fe042623          	sw	zero,-20(s0)
  while(str[pos] != 0) {
 1b4:	03c0006f          	j	1f0 <sendstring+0x54>
    sendchar(str[pos++]);
 1b8:	fec42783          	lw	a5,-20(s0)
 1bc:	00178713          	addi	a4,a5,1
 1c0:	fee42623          	sw	a4,-20(s0)
 1c4:	00078713          	mv	a4,a5
 1c8:	fdc42783          	lw	a5,-36(s0)
 1cc:	00e787b3          	add	a5,a5,a4
 1d0:	0007c783          	lbu	a5,0(a5)
 1d4:	00078513          	mv	a0,a5
 1d8:	f95ff0ef          	jal	ra,16c <sendchar>
    while((uart_status[0] & 1)== 1) {};
 1dc:	00000013          	nop
 1e0:	8741a783          	lw	a5,-1932(gp) # 1ac0 <uart_status>
 1e4:	0007c783          	lbu	a5,0(a5)
 1e8:	0017f793          	andi	a5,a5,1
 1ec:	fe079ae3          	bnez	a5,1e0 <sendstring+0x44>
  while(str[pos] != 0) {
 1f0:	fec42783          	lw	a5,-20(s0)
 1f4:	fdc42703          	lw	a4,-36(s0)
 1f8:	00f707b3          	add	a5,a4,a5
 1fc:	0007c783          	lbu	a5,0(a5)
 200:	fa079ce3          	bnez	a5,1b8 <sendstring+0x1c>
  }
}
 204:	00000013          	nop
 208:	00000013          	nop
 20c:	02c12083          	lw	ra,44(sp)
 210:	02812403          	lw	s0,40(sp)
 214:	03010113          	addi	sp,sp,48
 218:	00008067          	ret

0000021c <load>:


int load(  unsigned char * load_ram_base) {
 21c:	fc010113          	addi	sp,sp,-64
 220:	02112e23          	sw	ra,60(sp)
 224:	02812c23          	sw	s0,56(sp)
 228:	04010413          	addi	s0,sp,64
 22c:	fca42623          	sw	a0,-52(s0)

  unsigned int len=0;
 230:	fe042623          	sw	zero,-20(s0)

  unsigned char in=0;
 234:	fc040fa3          	sb	zero,-33(s0)

  int blopck=0;
 238:	fc042c23          	sw	zero,-40(s0)
  int perc_count=0;
 23c:	fe042423          	sw	zero,-24(s0)
  int perc_top=0;
 240:	fc042a23          	sw	zero,-44(s0)
  // read length
  load_ram_base=  (unsigned char *)0x10000;
 244:	000107b7          	lui	a5,0x10
 248:	fcf42623          	sw	a5,-52(s0)


  //sendstring("|\e[32C|\e[33D");
  sendstring("|................................|\n ");
 24c:	000017b7          	lui	a5,0x1
 250:	94478513          	addi	a0,a5,-1724 # 944 <_exit+0x4>
 254:	f49ff0ef          	jal	ra,19c <sendstring>


  for(int i=0;i<5;i++) {
 258:	fe042223          	sw	zero,-28(s0)
 25c:	04c0006f          	j	2a8 <load+0x8c>
      while((uart_status[0] & 2)!= 2) {};
 260:	00000013          	nop
 264:	8741a783          	lw	a5,-1932(gp) # 1ac0 <uart_status>
 268:	0007c783          	lbu	a5,0(a5)
 26c:	0027f793          	andi	a5,a5,2
 270:	fe078ae3          	beqz	a5,264 <load+0x48>
      in = uart_in[0];
 274:	8781a783          	lw	a5,-1928(gp) # 1ac4 <uart_in>
 278:	0007c783          	lbu	a5,0(a5)
 27c:	fcf40fa3          	sb	a5,-33(s0)
      len = len << 8;
 280:	fec42783          	lw	a5,-20(s0)
 284:	00879793          	slli	a5,a5,0x8
 288:	fef42623          	sw	a5,-20(s0)
      len = len +(  unsigned int)in;
 28c:	fdf44783          	lbu	a5,-33(s0)
 290:	fec42703          	lw	a4,-20(s0)
 294:	00f707b3          	add	a5,a4,a5
 298:	fef42623          	sw	a5,-20(s0)
  for(int i=0;i<5;i++) {
 29c:	fe442783          	lw	a5,-28(s0)
 2a0:	00178793          	addi	a5,a5,1
 2a4:	fef42223          	sw	a5,-28(s0)
 2a8:	fe442703          	lw	a4,-28(s0)
 2ac:	00400793          	li	a5,4
 2b0:	fae7d8e3          	bge	a5,a4,260 <load+0x44>
  }
  perc_top = len >>5;
 2b4:	fec42783          	lw	a5,-20(s0)
 2b8:	0057d793          	srli	a5,a5,0x5
 2bc:	fcf42a23          	sw	a5,-44(s0)
  led_state=led_state^0x08;
 2c0:	8681c783          	lbu	a5,-1944(gp) # 1ab4 <led_state>
 2c4:	0087c793          	xori	a5,a5,8
 2c8:	0ff7f713          	andi	a4,a5,255
 2cc:	86e18423          	sb	a4,-1944(gp) # 1ab4 <led_state>
  setled();
 2d0:	e75ff0ef          	jal	ra,144 <setled>




  for(int i=0;i<len;i++) {
 2d4:	fe042023          	sw	zero,-32(s0)
 2d8:	0680006f          	j	340 <load+0x124>
    while((uart_status[0] & 2)!= 2) {};
 2dc:	00000013          	nop
 2e0:	8741a783          	lw	a5,-1932(gp) # 1ac0 <uart_status>
 2e4:	0007c783          	lbu	a5,0(a5)
 2e8:	0027f793          	andi	a5,a5,2
 2ec:	fe078ae3          	beqz	a5,2e0 <load+0xc4>
    in = uart_in[0];
 2f0:	8781a783          	lw	a5,-1928(gp) # 1ac4 <uart_in>
 2f4:	0007c783          	lbu	a5,0(a5)
 2f8:	fcf40fa3          	sb	a5,-33(s0)
    load_ram_base[i]=in;
 2fc:	fe042783          	lw	a5,-32(s0)
 300:	fcc42703          	lw	a4,-52(s0)
 304:	00f707b3          	add	a5,a4,a5
 308:	fdf44703          	lbu	a4,-33(s0)
 30c:	00e78023          	sb	a4,0(a5)
    perc_count++;
 310:	fe842783          	lw	a5,-24(s0)
 314:	00178793          	addi	a5,a5,1
 318:	fef42423          	sw	a5,-24(s0)
    if(perc_count == perc_top) {
 31c:	fe842703          	lw	a4,-24(s0)
 320:	fd442783          	lw	a5,-44(s0)
 324:	00f71863          	bne	a4,a5,334 <load+0x118>
      sendchar('X');
 328:	05800513          	li	a0,88
 32c:	e41ff0ef          	jal	ra,16c <sendchar>
        perc_count=0;
 330:	fe042423          	sw	zero,-24(s0)
  for(int i=0;i<len;i++) {
 334:	fe042783          	lw	a5,-32(s0)
 338:	00178793          	addi	a5,a5,1
 33c:	fef42023          	sw	a5,-32(s0)
 340:	fe042783          	lw	a5,-32(s0)
 344:	fec42703          	lw	a4,-20(s0)
 348:	f8e7eae3          	bltu	a5,a4,2dc <load+0xc0>
    }
  }
  while((uart_status[0] & 1)== 1) {};
 34c:	00000013          	nop
 350:	8741a783          	lw	a5,-1932(gp) # 1ac0 <uart_status>
 354:	0007c783          	lbu	a5,0(a5)
 358:	0017f793          	andi	a5,a5,1
 35c:	fe079ae3          	bnez	a5,350 <load+0x134>
  sendchar('\n');
 360:	00a00513          	li	a0,10
 364:	e09ff0ef          	jal	ra,16c <sendchar>
  while((uart_status[0] & 1)== 1) {};
 368:	00000013          	nop
 36c:	8741a783          	lw	a5,-1932(gp) # 1ac0 <uart_status>
 370:	0007c783          	lbu	a5,0(a5)
 374:	0017f793          	andi	a5,a5,1
 378:	fe079ae3          	bnez	a5,36c <load+0x150>
  led_state=4;
 37c:	00400713          	li	a4,4
 380:	86e18423          	sb	a4,-1944(gp) # 1ab4 <led_state>
  setled();
 384:	dc1ff0ef          	jal	ra,144 <setled>
  return 0;
 388:	00000793          	li	a5,0
}
 38c:	00078513          	mv	a0,a5
 390:	03c12083          	lw	ra,60(sp)
 394:	03812403          	lw	s0,56(sp)
 398:	04010113          	addi	sp,sp,64
 39c:	00008067          	ret

000003a0 <run>:

int run(  unsigned char * load_ram_base) {
 3a0:	fd010113          	addi	sp,sp,-48
 3a4:	02112623          	sw	ra,44(sp)
 3a8:	02812423          	sw	s0,40(sp)
 3ac:	03010413          	addi	s0,sp,48
 3b0:	fca42e23          	sw	a0,-36(s0)
  int  start = ((int*)load_ram_base)[6];
 3b4:	fdc42783          	lw	a5,-36(s0)
 3b8:	0187a783          	lw	a5,24(a5)
 3bc:	fef42623          	sw	a5,-20(s0)
  int (*boot_main)(void) = (int (*)())(start);
 3c0:	fec42783          	lw	a5,-20(s0)
 3c4:	fef42423          	sw	a5,-24(s0)
  return boot_main();
 3c8:	fe842783          	lw	a5,-24(s0)
 3cc:	000780e7          	jalr	a5
 3d0:	00050793          	mv	a5,a0
}
 3d4:	00078513          	mv	a0,a5
 3d8:	02c12083          	lw	ra,44(sp)
 3dc:	02812403          	lw	s0,40(sp)
 3e0:	03010113          	addi	sp,sp,48
 3e4:	00008067          	ret

000003e8 <main>:

int main() {
 3e8:	fa010113          	addi	sp,sp,-96
 3ec:	04112e23          	sw	ra,92(sp)
 3f0:	04812c23          	sw	s0,88(sp)
 3f4:	06010413          	addi	s0,sp,96

  unsigned char * load_ram_base=  (unsigned char *)0x10000;
 3f8:	000107b7          	lui	a5,0x10
 3fc:	fef42623          	sw	a5,-20(s0)

  void (*traps[16])();

  sendstring("CRISC-V Bootloader v0.1\n");
 400:	000017b7          	lui	a5,0x1
 404:	96c78513          	addi	a0,a5,-1684 # 96c <_exit+0x2c>
 408:	d95ff0ef          	jal	ra,19c <sendstring>
  if(STDFN_INC) {
    traps[11] =syscall;
 40c:	67c00793          	li	a5,1660
 410:	fcf42c23          	sw	a5,-40(s0)
    asm("csrw  mtvec, %0" :  : "r"(&traps));
 414:	fac40793          	addi	a5,s0,-84
 418:	30579073          	csrw	mtvec,a5
    sendstring("Stdfn (v0.1) ECALL Available\n");
 41c:	000017b7          	lui	a5,0x1
 420:	98878513          	addi	a0,a5,-1656 # 988 <_exit+0x48>
 424:	d79ff0ef          	jal	ra,19c <sendstring>
//    sendstring("UART Available\n");
//    sendstring("SPI, I2C Not Available\n");
  }


  led_state=3;
 428:	00300713          	li	a4,3
 42c:	86e18423          	sb	a4,-1944(gp) # 1ab4 <led_state>
  setled();
 430:	d15ff0ef          	jal	ra,144 <setled>

  if(load(load_ram_base)) {
 434:	fec42503          	lw	a0,-20(s0)
 438:	de5ff0ef          	jal	ra,21c <load>
 43c:	00050793          	mv	a5,a0
 440:	00078a63          	beqz	a5,454 <main+0x6c>
      sendstring("Load failure\n");
 444:	000017b7          	lui	a5,0x1
 448:	9a878513          	addi	a0,a5,-1624 # 9a8 <_exit+0x68>
 44c:	d51ff0ef          	jal	ra,19c <sendstring>
 450:	0100006f          	j	460 <main+0x78>
  } else {
      sendstring("Load complete\n");
 454:	000017b7          	lui	a5,0x1
 458:	9b878513          	addi	a0,a5,-1608 # 9b8 <_exit+0x78>
 45c:	d41ff0ef          	jal	ra,19c <sendstring>
  }


  sendstring("Starting\n");
 460:	000017b7          	lui	a5,0x1
 464:	9c878513          	addi	a0,a5,-1592 # 9c8 <_exit+0x88>
 468:	d35ff0ef          	jal	ra,19c <sendstring>
  run(load_ram_base);
 46c:	fec42503          	lw	a0,-20(s0)
 470:	f31ff0ef          	jal	ra,3a0 <run>
  sendstring("Finished\n");
 474:	000017b7          	lui	a5,0x1
 478:	9d478513          	addi	a0,a5,-1580 # 9d4 <_exit+0x94>
 47c:	d21ff0ef          	jal	ra,19c <sendstring>
  return 0;
 480:	00000793          	li	a5,0

}
 484:	00078513          	mv	a0,a5
 488:	05c12083          	lw	ra,92(sp)
 48c:	05812403          	lw	s0,88(sp)
 490:	06010113          	addi	sp,sp,96
 494:	00008067          	ret

00000498 <_write>:
#include "stdfn.h"
#include <sys/asm.h>
#include <machine/syscall.h>

int _write (int fd, char *buf, int count) {
 498:	fd010113          	addi	sp,sp,-48
 49c:	02812623          	sw	s0,44(sp)
 4a0:	03010413          	addi	s0,sp,48
 4a4:	fca42e23          	sw	a0,-36(s0)
 4a8:	fcb42c23          	sw	a1,-40(s0)
 4ac:	fcc42a23          	sw	a2,-44(s0)
  char * uart = (char *)0xffffff01;
 4b0:	f0100793          	li	a5,-255
 4b4:	fef42423          	sw	a5,-24(s0)
  char * uart_status = (char *)0xffffff02;
 4b8:	f0200793          	li	a5,-254
 4bc:	fef42223          	sw	a5,-28(s0)
  for(int i=0;i<count;i++) {
 4c0:	fe042623          	sw	zero,-20(s0)
 4c4:	03c0006f          	j	500 <_write+0x68>
    uart[0] = buf[i];
 4c8:	fec42783          	lw	a5,-20(s0)
 4cc:	fd842703          	lw	a4,-40(s0)
 4d0:	00f707b3          	add	a5,a4,a5
 4d4:	0007c703          	lbu	a4,0(a5)
 4d8:	fe842783          	lw	a5,-24(s0)
 4dc:	00e78023          	sb	a4,0(a5)
    while((uart_status[0] & 1)== 1) {};
 4e0:	00000013          	nop
 4e4:	fe442783          	lw	a5,-28(s0)
 4e8:	0007c783          	lbu	a5,0(a5)
 4ec:	0017f793          	andi	a5,a5,1
 4f0:	fe079ae3          	bnez	a5,4e4 <_write+0x4c>
  for(int i=0;i<count;i++) {
 4f4:	fec42783          	lw	a5,-20(s0)
 4f8:	00178793          	addi	a5,a5,1
 4fc:	fef42623          	sw	a5,-20(s0)
 500:	fec42703          	lw	a4,-20(s0)
 504:	fd442783          	lw	a5,-44(s0)
 508:	fcf740e3          	blt	a4,a5,4c8 <_write+0x30>
  }
  return count;
 50c:	fd442783          	lw	a5,-44(s0)
}
 510:	00078513          	mv	a0,a5
 514:	02c12403          	lw	s0,44(sp)
 518:	03010113          	addi	sp,sp,48
 51c:	00008067          	ret

00000520 <_read>:

int _read (int fd, char *buf, int count) {
 520:	fd010113          	addi	sp,sp,-48
 524:	02812623          	sw	s0,44(sp)
 528:	03010413          	addi	s0,sp,48
 52c:	fca42e23          	sw	a0,-36(s0)
 530:	fcb42c23          	sw	a1,-40(s0)
 534:	fcc42a23          	sw	a2,-44(s0)
  char * uart_in = (char *)0xffffff03;
 538:	f0300793          	li	a5,-253
 53c:	fef42623          	sw	a5,-20(s0)
  char * uart_status = (char *)0xffffff02;
 540:	f0200793          	li	a5,-254
 544:	fef42423          	sw	a5,-24(s0)
  int pos=0;
 548:	fe042223          	sw	zero,-28(s0)
  while(pos<count){
 54c:	02c0006f          	j	578 <_read+0x58>
    if((uart_status[0] & 2)== 2) {
 550:	fe842783          	lw	a5,-24(s0)
 554:	0007c783          	lbu	a5,0(a5)
 558:	0027f793          	andi	a5,a5,2
 55c:	00078e63          	beqz	a5,578 <_read+0x58>
      buf[pos]=uart_in[0];
 560:	fe442783          	lw	a5,-28(s0)
 564:	fd842703          	lw	a4,-40(s0)
 568:	00f707b3          	add	a5,a4,a5
 56c:	fec42703          	lw	a4,-20(s0)
 570:	00074703          	lbu	a4,0(a4)
 574:	00e78023          	sb	a4,0(a5)
  while(pos<count){
 578:	fe442703          	lw	a4,-28(s0)
 57c:	fd442783          	lw	a5,-44(s0)
 580:	fcf748e3          	blt	a4,a5,550 <_read+0x30>
    }
  }
  return count;
 584:	fd442783          	lw	a5,-44(s0)
}
 588:	00078513          	mv	a0,a5
 58c:	02c12403          	lw	s0,44(sp)
 590:	03010113          	addi	sp,sp,48
 594:	00008067          	ret

00000598 <_lseek>:

int _lseek(int fd, off_t offset, int whence) {
 598:	fe010113          	addi	sp,sp,-32
 59c:	00812e23          	sw	s0,28(sp)
 5a0:	02010413          	addi	s0,sp,32
 5a4:	fea42623          	sw	a0,-20(s0)
 5a8:	feb42423          	sw	a1,-24(s0)
 5ac:	fec42223          	sw	a2,-28(s0)
  return 0;
 5b0:	00000793          	li	a5,0
}
 5b4:	00078513          	mv	a0,a5
 5b8:	01c12403          	lw	s0,28(sp)
 5bc:	02010113          	addi	sp,sp,32
 5c0:	00008067          	ret

000005c4 <_fstat>:

int _fstat (int file, struct stat *buf) {
 5c4:	fe010113          	addi	sp,sp,-32
 5c8:	00812e23          	sw	s0,28(sp)
 5cc:	02010413          	addi	s0,sp,32
 5d0:	fea42623          	sw	a0,-20(s0)
 5d4:	feb42423          	sw	a1,-24(s0)
  return  0;
 5d8:	00000793          	li	a5,0
}
 5dc:	00078513          	mv	a0,a5
 5e0:	01c12403          	lw	s0,28(sp)
 5e4:	02010113          	addi	sp,sp,32
 5e8:	00008067          	ret

000005ec <_close>:

int _close(int fd) {
 5ec:	fe010113          	addi	sp,sp,-32
 5f0:	00812e23          	sw	s0,28(sp)
 5f4:	02010413          	addi	s0,sp,32
 5f8:	fea42623          	sw	a0,-20(s0)
  return 0;
 5fc:	00000793          	li	a5,0
}
 600:	00078513          	mv	a0,a5
 604:	01c12403          	lw	s0,28(sp)
 608:	02010113          	addi	sp,sp,32
 60c:	00008067          	ret

00000610 <_getpid>:

pid_t _getpid() {
 610:	ff010113          	addi	sp,sp,-16
 614:	00812623          	sw	s0,12(sp)
 618:	01010413          	addi	s0,sp,16
  return 23;
 61c:	01700793          	li	a5,23
}
 620:	00078513          	mv	a0,a5
 624:	00c12403          	lw	s0,12(sp)
 628:	01010113          	addi	sp,sp,16
 62c:	00008067          	ret

00000630 <_kill>:

int _kill(pid_t pid, int sig){
 630:	fe010113          	addi	sp,sp,-32
 634:	00812e23          	sw	s0,28(sp)
 638:	02010413          	addi	s0,sp,32
 63c:	fea42623          	sw	a0,-20(s0)
 640:	feb42423          	sw	a1,-24(s0)
  return 0;
 644:	00000793          	li	a5,0
}
 648:	00078513          	mv	a0,a5
 64c:	01c12403          	lw	s0,28(sp)
 650:	02010113          	addi	sp,sp,32
 654:	00008067          	ret

00000658 <_brk>:


int _brk(int incr) {
 658:	fe010113          	addi	sp,sp,-32
 65c:	00812e23          	sw	s0,28(sp)
 660:	02010413          	addi	s0,sp,32
 664:	fea42623          	sw	a0,-20(s0)

  return 0;
 668:	00000793          	li	a5,0
}
 66c:	00078513          	mv	a0,a5
 670:	01c12403          	lw	s0,28(sp)
 674:	02010113          	addi	sp,sp,32
 678:	00008067          	ret

0000067c <syscall>:

void syscall() __attribute__ ((interrupt ("machine")));

void syscall() {
 67c:	f9010113          	addi	sp,sp,-112
 680:	06112623          	sw	ra,108(sp)
 684:	06512423          	sw	t0,104(sp)
 688:	06612223          	sw	t1,100(sp)
 68c:	06712023          	sw	t2,96(sp)
 690:	04812e23          	sw	s0,92(sp)
 694:	04a12c23          	sw	a0,88(sp)
 698:	04b12a23          	sw	a1,84(sp)
 69c:	04c12823          	sw	a2,80(sp)
 6a0:	04d12623          	sw	a3,76(sp)
 6a4:	04e12423          	sw	a4,72(sp)
 6a8:	04f12223          	sw	a5,68(sp)
 6ac:	05012023          	sw	a6,64(sp)
 6b0:	03112e23          	sw	a7,60(sp)
 6b4:	03c12c23          	sw	t3,56(sp)
 6b8:	03d12a23          	sw	t4,52(sp)
 6bc:	03e12823          	sw	t5,48(sp)
 6c0:	03f12623          	sw	t6,44(sp)
 6c4:	07010413          	addi	s0,sp,112
  int a0,a1,a2,a3,a4,a5,a7;
  int ret;
  // These are on stack so lets get them from there
  // so they don't get trashed
  asm("lw %0, 60(sp)" : "=r"(a7) : );
 6c8:	03c12783          	lw	a5,60(sp)
 6cc:	faf42423          	sw	a5,-88(s0)
  asm("lw %0, 88(sp)" : "=r"(a0) : );
 6d0:	05812783          	lw	a5,88(sp)
 6d4:	faf42223          	sw	a5,-92(s0)
  asm("lw %0, 84(sp)" : "=r"(a1) : );
 6d8:	05412783          	lw	a5,84(sp)
 6dc:	faf42023          	sw	a5,-96(s0)
  asm("lw %0, 80(sp)" : "=r"(a2) : );
 6e0:	05012783          	lw	a5,80(sp)
 6e4:	f8f42e23          	sw	a5,-100(s0)
  asm("lw %0, 76(sp)" : "=r"(a3) : );
 6e8:	04c12783          	lw	a5,76(sp)
 6ec:	f8f42c23          	sw	a5,-104(s0)
  asm("lw %0, 72(sp)" : "=r"(a4) : );
 6f0:	04812783          	lw	a5,72(sp)
 6f4:	f8f42a23          	sw	a5,-108(s0)
  asm("lw %0, 68(sp)" : "=r"(a5) : );
 6f8:	04412783          	lw	a5,68(sp)
 6fc:	f8f42823          	sw	a5,-112(s0)
;


  switch (a7) {
 700:	fa842703          	lw	a4,-88(s0)
 704:	0d600793          	li	a5,214
 708:	10f70863          	beq	a4,a5,818 <syscall+0x19c>
 70c:	fa842703          	lw	a4,-88(s0)
 710:	0d600793          	li	a5,214
 714:	10e7ca63          	blt	a5,a4,828 <syscall+0x1ac>
 718:	fa842703          	lw	a4,-88(s0)
 71c:	0b000793          	li	a5,176
 720:	0cf70c63          	beq	a4,a5,7f8 <syscall+0x17c>
 724:	fa842703          	lw	a4,-88(s0)
 728:	0b000793          	li	a5,176
 72c:	0ee7ce63          	blt	a5,a4,828 <syscall+0x1ac>
 730:	fa842703          	lw	a4,-88(s0)
 734:	05000793          	li	a5,80
 738:	02e7cc63          	blt	a5,a4,770 <syscall+0xf4>
 73c:	fa842703          	lw	a4,-88(s0)
 740:	03900793          	li	a5,57
 744:	0ef74263          	blt	a4,a5,828 <syscall+0x1ac>
 748:	fa842783          	lw	a5,-88(s0)
 74c:	fc778793          	addi	a5,a5,-57
 750:	01700713          	li	a4,23
 754:	0cf76a63          	bltu	a4,a5,828 <syscall+0x1ac>
 758:	00279713          	slli	a4,a5,0x2
 75c:	000017b7          	lui	a5,0x1
 760:	9e078793          	addi	a5,a5,-1568 # 9e0 <_exit+0xa0>
 764:	00f707b3          	add	a5,a4,a5
 768:	0007a783          	lw	a5,0(a5)
 76c:	00078067          	jr	a5
 770:	fa842703          	lw	a4,-88(s0)
 774:	08100793          	li	a5,129
 778:	08f70663          	beq	a4,a5,804 <syscall+0x188>
 77c:	0ac0006f          	j	828 <syscall+0x1ac>
    case SYS_write:
      ret=_write (a0, (char *)a1, a2);
 780:	fa042783          	lw	a5,-96(s0)
 784:	f9c42603          	lw	a2,-100(s0)
 788:	00078593          	mv	a1,a5
 78c:	fa442503          	lw	a0,-92(s0)
 790:	d09ff0ef          	jal	ra,498 <_write>
 794:	faa42623          	sw	a0,-84(s0)
       break;
 798:	0980006f          	j	830 <syscall+0x1b4>
    case SYS_read:
      ret=_read (a0, (char *)a1, a2);
 79c:	fa042783          	lw	a5,-96(s0)
 7a0:	f9c42603          	lw	a2,-100(s0)
 7a4:	00078593          	mv	a1,a5
 7a8:	fa442503          	lw	a0,-92(s0)
 7ac:	d75ff0ef          	jal	ra,520 <_read>
 7b0:	faa42623          	sw	a0,-84(s0)
       break;
 7b4:	07c0006f          	j	830 <syscall+0x1b4>
    case SYS_lseek:
      ret=_lseek(a0, (off_t)a1 ,a2);
 7b8:	f9c42603          	lw	a2,-100(s0)
 7bc:	fa042583          	lw	a1,-96(s0)
 7c0:	fa442503          	lw	a0,-92(s0)
 7c4:	dd5ff0ef          	jal	ra,598 <_lseek>
 7c8:	faa42623          	sw	a0,-84(s0)
       break;
 7cc:	0640006f          	j	830 <syscall+0x1b4>
    case SYS_fstat:
      ret=_fstat (a0, (struct stat *)a1);
 7d0:	fa042783          	lw	a5,-96(s0)
 7d4:	00078593          	mv	a1,a5
 7d8:	fa442503          	lw	a0,-92(s0)
 7dc:	de9ff0ef          	jal	ra,5c4 <_fstat>
 7e0:	faa42623          	sw	a0,-84(s0)
       break;
 7e4:	04c0006f          	j	830 <syscall+0x1b4>
    case SYS_close:
      ret=_close(a0);
 7e8:	fa442503          	lw	a0,-92(s0)
 7ec:	e01ff0ef          	jal	ra,5ec <_close>
 7f0:	faa42623          	sw	a0,-84(s0)
       break;
 7f4:	03c0006f          	j	830 <syscall+0x1b4>
    case SYS_getgid:
      ret=_getpid();
 7f8:	e19ff0ef          	jal	ra,610 <_getpid>
 7fc:	faa42623          	sw	a0,-84(s0)
       break;
 800:	0300006f          	j	830 <syscall+0x1b4>
     case SYS_kill:
       ret=_kill((pid_t)a0,a1);
 804:	fa042583          	lw	a1,-96(s0)
 808:	fa442503          	lw	a0,-92(s0)
 80c:	e25ff0ef          	jal	ra,630 <_kill>
 810:	faa42623          	sw	a0,-84(s0)
       break;
 814:	01c0006f          	j	830 <syscall+0x1b4>
       case SYS_brk:
         ret=_brk(a0);
 818:	fa442503          	lw	a0,-92(s0)
 81c:	e3dff0ef          	jal	ra,658 <_brk>
 820:	faa42623          	sw	a0,-84(s0)
         break;
 824:	00c0006f          	j	830 <syscall+0x1b4>
      default:
        ret=0;
 828:	fa042623          	sw	zero,-84(s0)
        break;
 82c:	00000013          	nop
     }

    asm("sw  %0, 88(sp)" :  : "r"(ret));
 830:	fac42783          	lw	a5,-84(s0)
 834:	04f12c23          	sw	a5,88(sp)
}
 838:	00000013          	nop
 83c:	06c12083          	lw	ra,108(sp)
 840:	06812283          	lw	t0,104(sp)
 844:	06412303          	lw	t1,100(sp)
 848:	06012383          	lw	t2,96(sp)
 84c:	05c12403          	lw	s0,92(sp)
 850:	05812503          	lw	a0,88(sp)
 854:	05412583          	lw	a1,84(sp)
 858:	05012603          	lw	a2,80(sp)
 85c:	04c12683          	lw	a3,76(sp)
 860:	04812703          	lw	a4,72(sp)
 864:	04412783          	lw	a5,68(sp)
 868:	04012803          	lw	a6,64(sp)
 86c:	03c12883          	lw	a7,60(sp)
 870:	03812e03          	lw	t3,56(sp)
 874:	03412e83          	lw	t4,52(sp)
 878:	03012f03          	lw	t5,48(sp)
 87c:	02c12f83          	lw	t6,44(sp)
 880:	07010113          	addi	sp,sp,112
 884:	30200073          	mret

00000888 <__libc_init_array>:
 888:	ff010113          	addi	sp,sp,-16
 88c:	00812423          	sw	s0,8(sp)
 890:	00912223          	sw	s1,4(sp)
 894:	00002437          	lui	s0,0x2
 898:	000024b7          	lui	s1,0x2
 89c:	a4448793          	addi	a5,s1,-1468 # 1a44 <__frame_dummy_init_array_entry>
 8a0:	a4440413          	addi	s0,s0,-1468 # 1a44 <__frame_dummy_init_array_entry>
 8a4:	40f40433          	sub	s0,s0,a5
 8a8:	01212023          	sw	s2,0(sp)
 8ac:	00112623          	sw	ra,12(sp)
 8b0:	40245413          	srai	s0,s0,0x2
 8b4:	a4448493          	addi	s1,s1,-1468
 8b8:	00000913          	li	s2,0
 8bc:	04891063          	bne	s2,s0,8fc <__libc_init_array+0x74>
 8c0:	000024b7          	lui	s1,0x2
 8c4:	00002437          	lui	s0,0x2
 8c8:	a4448793          	addi	a5,s1,-1468 # 1a44 <__frame_dummy_init_array_entry>
 8cc:	a4840413          	addi	s0,s0,-1464 # 1a48 <__do_global_dtors_aux_fini_array_entry>
 8d0:	40f40433          	sub	s0,s0,a5
 8d4:	40245413          	srai	s0,s0,0x2
 8d8:	a4448493          	addi	s1,s1,-1468
 8dc:	00000913          	li	s2,0
 8e0:	02891863          	bne	s2,s0,910 <__libc_init_array+0x88>
 8e4:	00c12083          	lw	ra,12(sp)
 8e8:	00812403          	lw	s0,8(sp)
 8ec:	00412483          	lw	s1,4(sp)
 8f0:	00012903          	lw	s2,0(sp)
 8f4:	01010113          	addi	sp,sp,16
 8f8:	00008067          	ret
 8fc:	0004a783          	lw	a5,0(s1)
 900:	00190913          	addi	s2,s2,1
 904:	00448493          	addi	s1,s1,4
 908:	000780e7          	jalr	a5
 90c:	fb1ff06f          	j	8bc <__libc_init_array+0x34>
 910:	0004a783          	lw	a5,0(s1)
 914:	00190913          	addi	s2,s2,1
 918:	00448493          	addi	s1,s1,4
 91c:	000780e7          	jalr	a5
 920:	fc1ff06f          	j	8e0 <__libc_init_array+0x58>

00000924 <memset>:
 924:	00050313          	mv	t1,a0
 928:	00060a63          	beqz	a2,93c <memset+0x18>
 92c:	00b30023          	sb	a1,0(t1) # 138 <frame_dummy+0x14>
 930:	fff60613          	addi	a2,a2,-1
 934:	00130313          	addi	t1,t1,1
 938:	fe061ae3          	bnez	a2,92c <memset+0x8>
 93c:	00008067          	ret

00000940 <_exit>:
 940:	0000006f          	j	940 <_exit>
