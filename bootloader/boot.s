	.file	"boot.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
# GNU C17 (GCC) version 10.1.0 (riscv64-unknown-elf)
#	compiled by GNU C version 9.3.0, GMP version 6.2.0, MPFR version 4.0.2, MPC version 1.1.0, isl version none
# warning: GMP header version 6.2.0 differs from library version 6.3.0.
# warning: MPFR header version 4.0.2 differs from library version 4.2.1.
# warning: MPC header version 1.1.0 differs from library version 1.3.1.
# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed:  -imultilib rv32i/ilp32 boot.c -march=rv32i -mabi=ilp32
# -mtune=rocket -auxbase-strip boot.s -g -O0 -fverbose-asm
# options enabled:  -faggressive-loop-optimizations -fallocation-dce
# -fauto-inc-dec -fdelete-null-pointer-checks -fdwarf2-cfi-asm
# -fearly-inlining -feliminate-unused-debug-symbols
# -feliminate-unused-debug-types -ffp-int-builtin-inexact -ffunction-cse
# -fgcse-lm -fgnu-unique -fident -finline-atomics -fipa-stack-alignment
# -fira-hoist-pressure -fira-share-save-slots -fira-share-spill-slots
# -fivopts -fkeep-static-consts -fleading-underscore -flifetime-dse
# -fmath-errno -fmerge-debug-strings -fpeephole -fplt
# -fprefetch-loop-arrays -freg-struct-return
# -fsched-critical-path-heuristic -fsched-dep-count-heuristic
# -fsched-group-heuristic -fsched-interblock -fsched-last-insn-heuristic
# -fsched-rank-heuristic -fsched-spec -fsched-spec-insn-heuristic
# -fsched-stalled-insns-dep -fschedule-fusion -fsemantic-interposition
# -fshow-column -fshrink-wrap-separate -fsigned-zeros
# -fsplit-ivs-in-unroller -fssa-backprop -fstdarg-opt
# -fstrict-volatile-bitfields -fsync-libcalls -ftrapping-math -ftree-cselim
# -ftree-forwprop -ftree-loop-if-convert -ftree-loop-im -ftree-loop-ivcanon
# -ftree-loop-optimize -ftree-parallelize-loops= -ftree-phiprop
# -ftree-reassoc -ftree-scev-cprop -funit-at-a-time -fverbose-asm
# -fzero-initialized-in-bss -mexplicit-relocs -mplt -mriscv-attribute
# -mstrict-align

	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.globl	FileHeader
	.bss
	.align	2
	.type	FileHeader, @object
	.size	FileHeader, 28
FileHeader:
	.zero	28
	.globl	led_state
	.section	.sdata,"aw"
	.type	led_state, @object
	.size	led_state, 1
led_state:
	.byte	1
	.globl	led
	.align	2
	.type	led, @object
	.size	led, 4
led:
	.word	-256
	.globl	uart
	.align	2
	.type	uart, @object
	.size	uart, 4
uart:
	.word	-255
	.globl	uart_status
	.align	2
	.type	uart_status, @object
	.size	uart_status, 4
uart_status:
	.word	-254
	.globl	uart_in
	.align	2
	.type	uart_in, @object
	.size	uart_in, 4
uart_in:
	.word	-253
	.globl	ftype
	.section	.sbss,"aw",@nobits
	.align	2
	.type	ftype, @object
	.size	ftype, 4
ftype:
	.zero	4
	.text
	.align	2
	.globl	setled
	.type	setled, @function
setled:
.LFB4:
	.file 1 "boot.c"
	.loc 1 35 15
	.cfi_startproc
	addi	sp,sp,-16	#,,
	.cfi_def_cfa_offset 16
	sw	s0,12(sp)	#,
	.cfi_offset 8, -4
	addi	s0,sp,16	#,,
	.cfi_def_cfa 8, 0
# boot.c:36:   led[0] = led_state;
	.loc 1 36 6
	lui	a5,%hi(led)	# tmp74,
	lw	a5,%lo(led)(a5)		# led.0_1, led
# boot.c:36:   led[0] = led_state;
	.loc 1 36 10
	lui	a4,%hi(led_state)	# tmp75,
	lbu	a4,%lo(led_state)(a4)	# led_state.1_2, led_state
	sb	a4,0(a5)	# led_state.1_2, *led.0_1
# boot.c:37: }
	.loc 1 37 1
	nop	
	lw	s0,12(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE4:
	.size	setled, .-setled
	.align	2
	.globl	sendchar
	.type	sendchar, @function
sendchar:     a7c:	92c1a783          	lw	a5,-1748(gp) # 3b34 <led>
# boot.c:40:   uart[0] = c;
	.loc 1 40 7
	lui	a5,%hi(uart)	# tmp75,
	lw	a5,%lo(uart)(a5)		# uart.2_1, uart
# boot.c:40:   uart[0] = c;
	.loc 1 40 11
	lbu	a4,-17(s0)	# tmp76, c
	sb	a4,0(a5)	# tmp76, *uart.2_1
# boot.c:41: }
	.loc 1 41 1
	nop	
	lw	s0,28(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE5:
	.size	sendchar, .-sendchar
	.align	2
	.globl	sendstring
	.type	sendstring, @function
sendstring:
.LFB6:
	.loc 1 45 29
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)	#,
	sw	s0,40(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)	# str, str
# boot.c:46:   int pos=0;
	.loc 1 46 7
	sw	zero,-20(s0)	#, pos
# boot.c:47:   while(str[pos] != 0) {
	.loc 1 47 8
	j	.L4		#
.L6:
# boot.c:48:         while((uart_status[0] & 1)== 1) {};
	.loc 1 48 14
	nop	
.L5:
# boot.c:48:         while((uart_status[0] & 1)== 1) {};
	.loc 1 48 27 discriminator 1
	lui	a5,%hi(uart_status)	# tmp83,
	lw	a5,%lo(uart_status)(a5)		# uart_status.3_1, uart_status
	lbu	a5,0(a5)	# _2, *uart_status.3_1
# boot.c:48:         while((uart_status[0] & 1)== 1) {};
	.loc 1 48 31 discriminator 1
	andi	a5,a5,1	#, _4, _3
# boot.c:48:         while((uart_status[0] & 1)== 1) {};
	.loc 1 48 14 discriminator 1
	bne	a5,zero,.L5	#, _4,,
# boot.c:49:     sendchar(str[pos++]);
	.loc 1 49 21
	lw	a5,-20(s0)		# pos.4_5, pos
	addi	a4,a5,1	#, tmp84, pos.4_5
	sw	a4,-20(s0)	# tmp84, pos
	mv	a4,a5	# pos.5_6, pos.4_5
# boot.c:49:     sendchar(str[pos++]);
	.loc 1 49 17
	lw	a5,-36(s0)		# tmp85, str
	add	a5,a5,a4	# pos.5_6, _7, tmp85
# boot.c:49:     sendchar(str[pos++]);
	.loc 1 49 5
	lbu	a5,0(a5)	# _8, *_7
	mv	a0,a5	#, _8
	call	sendchar		#
.L4:
# boot.c:47:   while(str[pos] != 0) {
	.loc 1 47 12
	lw	a5,-20(s0)		# pos.6_9, pos
	lw	a4,-36(s0)		# tmp86, str
	add	a5,a4,a5	# pos.6_9, _10, tmp86
	lbu	a5,0(a5)	# _11, *_10
# boot.c:47:   while(str[pos] != 0) {
	.loc 1 47 8
	bne	a5,zero,.L6	#, _11,,
# boot.c:52: }
	.loc 1 52 1
	nop	
	nop	
	lw	ra,44(sp)		#,
	.cfi_restore 1
	lw	s0,40(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE6:
	.size	sendstring, .-sendstring
	.section	.rodata
	.align	2
.LC0:
	.string	"RVF"
	.text
	.align	2
	.globl	waitForStart
	.type	waitForStart, @function
waitForStart:
.LFB7:
	.loc 1 54 21
	.cfi_startproc
	addi	sp,sp,-32	#,,
	.cfi_def_cfa_offset 32
	sw	s0,28(sp)	#,
	.cfi_offset 8, -4
	addi	s0,sp,32	#,,
	.cfi_def_cfa 8, 0
# boot.c:56:   char * start = "RVF";
	.loc 1 56 10
	lui	a5,%hi(.LC0)	# tmp82,
	addi	a5,a5,%lo(.LC0)	# tmp81, tmp82,
	sw	a5,-24(s0)	# tmp81, start
# boot.c:57:   int st_pos=0;
	.loc 1 57 7
	sw	zero,-20(s0)	#, st_pos
# boot.c:58:   while(st_pos<3) {
	.loc 1 58 8
	j	.L8		#
.L12:
# boot.c:59:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 59 12
	nop	
.L9:
# boot.c:59:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 59 25 discriminator 1
	lui	a5,%hi(uart_status)	# tmp83,
	lw	a5,%lo(uart_status)(a5)		# uart_status.7_1, uart_status
	lbu	a5,0(a5)	# _2, *uart_status.7_1
# boot.c:59:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 59 29 discriminator 1
	andi	a5,a5,2	#, _4, _3
# boot.c:59:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 59 12 discriminator 1
	beq	a5,zero,.L9	#, _4,,
# boot.c:60:       in = uart_in[0];
	.loc 1 60 19
	lui	a5,%hi(uart_in)	# tmp84,
	lw	a5,%lo(uart_in)(a5)		# uart_in.8_5, uart_in
# boot.c:60:       in = uart_in[0];
	.loc 1 60 10
	lbu	a5,0(a5)	# tmp85, *uart_in.8_5
	sb	a5,-25(s0)	# tmp85, in
# boot.c:61:       if(in == start[st_pos]) {
	.loc 1 61 21
	lw	a5,-20(s0)		# st_pos.9_6, st_pos
	lw	a4,-24(s0)		# tmp86, start
	add	a5,a4,a5	# st_pos.9_6, _7, tmp86
	lbu	a5,0(a5)	# _8, *_7
# boot.c:61:       if(in == start[st_pos]) {
	.loc 1 61 9
	lbu	a4,-25(s0)	# tmp87, in
	bne	a4,a5,.L10	#, tmp87, _8,
# boot.c:62:         st_pos++;
	.loc 1 62 15
	lw	a5,-20(s0)		# tmp89, st_pos
	addi	a5,a5,1	#, tmp88, tmp89
	sw	a5,-20(s0)	# tmp88, st_pos
	j	.L8		#
.L10:
# boot.c:65:         if(in == start[0]) 
	.loc 1 65 23
	lw	a5,-24(s0)		# tmp90, start
	lbu	a5,0(a5)	# _9, *start_11
# boot.c:65:         if(in == start[0]) 
	.loc 1 65 11
	lbu	a4,-25(s0)	# tmp91, in
	bne	a4,a5,.L11	#, tmp91, _9,
# boot.c:66:           st_pos=1;
	.loc 1 66 17
	li	a5,1		# tmp92,
	sw	a5,-20(s0)	# tmp92, st_pos
	j	.L8		#
.L11:
# boot.c:68:           st_pos=0;
	.loc 1 68 17
	sw	zero,-20(s0)	#, st_pos
.L8:
# boot.c:58:   while(st_pos<3) {
	.loc 1 58 8
	lw	a4,-20(s0)		# tmp93, st_pos
	li	a5,2		# tmp94,
	ble	a4,a5,.L12	#, tmp93, tmp94,
# boot.c:72: }
	.loc 1 72 1
	nop	
	nop	
	lw	s0,28(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE7:
	.size	waitForStart, .-waitForStart
	.align	2
	.globl	readBytes
	.type	readBytes, @function
readBytes:
.LFB8:
	.loc 1 74 45
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	s0,44(sp)	#,
	.cfi_offset 8, -4
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)	# buf, buf
	sw	a1,-40(s0)	# len, len
.LBB2:
# boot.c:75:   for(int i=0;i<len;i++) {
	.loc 1 75 11
	sw	zero,-20(s0)	#, i
# boot.c:75:   for(int i=0;i<len;i++) {
	.loc 1 75 3
	j	.L14		#
.L16:
# boot.c:76:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 76 12
	nop	
.L15:
# boot.c:76:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 76 25 discriminator 1
	lui	a5,%hi(uart_status)	# tmp80,
	lw	a5,%lo(uart_status)(a5)		# uart_status.10_1, uart_status
	lbu	a5,0(a5)	# _2, *uart_status.10_1
# boot.c:76:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 76 29 discriminator 1
	andi	a5,a5,2	#, _4, _3
# boot.c:76:       while((uart_status[0] & 2)!= 2) {};
	.loc 1 76 12 discriminator 1
	beq	a5,zero,.L15	#, _4,,
# boot.c:77:       buf[i] = uart_in[0];
	.loc 1 77 23 discriminator 2
	lui	a5,%hi(uart_in)	# tmp81,
	lw	a4,%lo(uart_in)(a5)		# uart_in.11_5, uart_in
# boot.c:77:       buf[i] = uart_in[0];
	.loc 1 77 10 discriminator 2
	lw	a5,-20(s0)		# i.12_6, i
	lw	a3,-36(s0)		# tmp82, buf
	add	a5,a3,a5	# i.12_6, _7, tmp82
# boot.c:77:       buf[i] = uart_in[0];
	.loc 1 77 23 discriminator 2
	lbu	a4,0(a4)	# _8, *uart_in.11_5
# boot.c:77:       buf[i] = uart_in[0];
	.loc 1 77 14 discriminator 2
	sb	a4,0(a5)	# _8, *_7
# boot.c:75:   for(int i=0;i<len;i++) {
	.loc 1 75 22 discriminator 2
	lw	a5,-20(s0)		# tmp84, i
	addi	a5,a5,1	#, tmp83, tmp84
	sw	a5,-20(s0)	# tmp83, i
.L14:
# boot.c:75:   for(int i=0;i<len;i++) {
	.loc 1 75 3 discriminator 1
	lw	a4,-20(s0)		# tmp85, i
	lw	a5,-40(s0)		# tmp86, len
	blt	a4,a5,.L16	#, tmp85, tmp86,
.LBE2:
# boot.c:79: }
	.loc 1 79 1
	nop	
	nop	
	lw	s0,44(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE8:
	.size	readBytes, .-readBytes
	.globl	fileHeader
	.bss
	.align	2
	.type	fileHeader, @object
	.size	fileHeader, 28
fileHeader:
	.zero	28
	.section	.rodata
	.align	2
.LC1:
	.string	"|................................|\n"
	.text
	.align	2
	.globl	load
	.type	load, @function
load:
.LFB9:
	.loc 1 82 12
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)	#,
	sw	s0,40(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
# boot.c:88:   int perc_count=0;
	.loc 1 88 7
	sw	zero,-20(s0)	#, perc_count
# boot.c:89:   int perc_top=0;
	.loc 1 89 7
	sw	zero,-32(s0)	#, perc_top
# boot.c:91:   unsigned char* load_ram_base=  (unsigned char *)0x10000;
	.loc 1 91 18
	li	a5,65536		# tmp97,
	sw	a5,-24(s0)	# tmp97, load_ram_base
# boot.c:93: sendstring("|................................|\n");
	.loc 1 93 1
	lui	a5,%hi(.LC1)	# tmp98,
	addi	a0,a5,%lo(.LC1)	#, tmp98,
	call	sendstring		#
# boot.c:96:   waitForStart();
	.loc 1 96 3
	call	waitForStart		#
# boot.c:98:   led_state=led_state^0x08;
	.loc 1 98 12
	lui	a5,%hi(led_state)	# tmp99,
	lbu	a5,%lo(led_state)(a5)	# led_state.13_1, led_state
	xori	a5,a5,8	#, tmp100, led_state.13_1
	andi	a4,a5,0xff	# _2, tmp100
	lui	a5,%hi(led_state)	# tmp101,
	sb	a4,%lo(led_state)(a5)	# _2, led_state
# boot.c:99:   setled();
	.loc 1 99 3
	call	setled		#
# boot.c:102:   readBytes((unsigned char *)(&fileHeader.type),1);
	.loc 1 102 3
	li	a1,1		#,
	lui	a5,%hi(fileHeader)	# tmp102,
	addi	a0,a5,%lo(fileHeader)	#, tmp102,
	call	readBytes		#
# boot.c:103:   readBytes((unsigned char *)(&fileHeader.name),20);
	.loc 1 103 3
	li	a1,20		#,
	lui	a5,%hi(fileHeader+1)	# tmp103,
	addi	a0,a5,%lo(fileHeader+1)	#, tmp103,
	call	readBytes		#
# boot.c:104:   readBytes((unsigned char *)(&fileHeader.length),4);
	.loc 1 104 3
	li	a1,4		#,
	lui	a5,%hi(fileHeader+24)	# tmp104,
	addi	a0,a5,%lo(fileHeader+24)	#, tmp104,
	call	readBytes		#
# boot.c:105:   perc_top = fileHeader.length >>5;
	.loc 1 105 24
	lui	a5,%hi(fileHeader)	# tmp105,
	addi	a5,a5,%lo(fileHeader)	# tmp106, tmp105,
	lw	a5,24(a5)		# _3, fileHeader.length
# boot.c:105:   perc_top = fileHeader.length >>5;
	.loc 1 105 32
	srli	a5,a5,5	#, _4, _3
# boot.c:105:   perc_top = fileHeader.length >>5;
	.loc 1 105 12
	sw	a5,-32(s0)	# _4, perc_top
# boot.c:107:   switch(fileHeader.type) {
	.loc 1 107 20
	lui	a5,%hi(fileHeader)	# tmp107,
	addi	a5,a5,%lo(fileHeader)	# tmp108, tmp107,
	lbu	a5,0(a5)	# _5, fileHeader.type
# boot.c:107:   switch(fileHeader.type) {
	.loc 1 107 3
	beq	a5,zero,.L18	#, _6,,
	li	a4,1		# tmp109,
	beq	a5,a4,.L19	#, _6, tmp109,
	j	.L29		#
.L18:
# boot.c:109:       sendchar('p');
	.loc 1 109 7
	li	a0,112		#,
	call	sendchar		#
# boot.c:110:       break;
	.loc 1 110 7
	j	.L21		#
.L19:
# boot.c:112:       load_ram_base=  (unsigned char *)0xC00000;
	.loc 1 112 20
	li	a5,12582912		# tmp110,
	sw	a5,-24(s0)	# tmp110, load_ram_base
# boot.c:113:       sendchar('f');
	.loc 1 113 7
	li	a0,102		#,
	call	sendchar		#
# boot.c:114:       break;
	.loc 1 114 7
	j	.L21		#
.L29:
# boot.c:116:       sendchar('?');
	.loc 1 116 7
	li	a0,63		#,
	call	sendchar		#
# boot.c:117:       break;
	.loc 1 117 7
	nop	
.L21:
.LBB3:
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 11
	sw	zero,-28(s0)	#, i
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 3
	j	.L22		#
.L25:
# boot.c:121:     while((uart_status[0] & 2)!= 2) {};
	.loc 1 121 10
	nop	
.L23:
# boot.c:121:     while((uart_status[0] & 2)!= 2) {};
	.loc 1 121 23 discriminator 1
	lui	a5,%hi(uart_status)	# tmp111,
	lw	a5,%lo(uart_status)(a5)		# uart_status.14_7, uart_status
	lbu	a5,0(a5)	# _8, *uart_status.14_7
# boot.c:121:     while((uart_status[0] & 2)!= 2) {};
	.loc 1 121 27 discriminator 1
	andi	a5,a5,2	#, _10, _9
# boot.c:121:     while((uart_status[0] & 2)!= 2) {};
	.loc 1 121 10 discriminator 1
	beq	a5,zero,.L23	#, _10,,
# boot.c:122:     in = uart_in[0];
	.loc 1 122 17
	lui	a5,%hi(uart_in)	# tmp112,
	lw	a5,%lo(uart_in)(a5)		# uart_in.15_11, uart_in
# boot.c:122:     in = uart_in[0];
	.loc 1 122 8
	lbu	a5,0(a5)	# tmp113, *uart_in.15_11
	sb	a5,-33(s0)	# tmp113, in
# boot.c:123:     load_ram_base[i]=in;
	.loc 1 123 18
	lw	a5,-28(s0)		# i.16_12, i
	lw	a4,-24(s0)		# tmp114, load_ram_base
	add	a5,a4,a5	# i.16_12, _13, tmp114
# boot.c:123:     load_ram_base[i]=in;
	.loc 1 123 21
	lbu	a4,-33(s0)	# tmp115, in
	sb	a4,0(a5)	# tmp115, *_13
# boot.c:124:     perc_count++;
	.loc 1 124 15
	lw	a5,-20(s0)		# tmp117, perc_count
	addi	a5,a5,1	#, tmp116, tmp117
	sw	a5,-20(s0)	# tmp116, perc_count
# boot.c:125:     if(perc_count == perc_top) {
	.loc 1 125 7
	lw	a4,-20(s0)		# tmp118, perc_count
	lw	a5,-32(s0)		# tmp119, perc_top
	bne	a4,a5,.L24	#, tmp118, tmp119,
# boot.c:126:       sendchar('X');
	.loc 1 126 7
	li	a0,88		#,
	call	sendchar		#
# boot.c:127:         perc_count=0;
	.loc 1 127 19
	sw	zero,-20(s0)	#, perc_count
.L24:
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 36 discriminator 2
	lw	a5,-28(s0)		# tmp121, i
	addi	a5,a5,1	#, tmp120, tmp121
	sw	a5,-28(s0)	# tmp120, i
.L22:
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 27 discriminator 1
	lui	a5,%hi(fileHeader)	# tmp122,
	addi	a5,a5,%lo(fileHeader)	# tmp123, tmp122,
	lw	a4,24(a5)		# _14, fileHeader.length
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 16 discriminator 1
	lw	a5,-28(s0)		# i.17_15, i
# boot.c:120:   for(int i=0;i<fileHeader.length;i++) {
	.loc 1 120 3 discriminator 1
	bgtu	a4,a5,.L25	#, _14, i.17_15,
.LBE3:
# boot.c:130:   while((uart_status[0] & 1)== 1) {};
	.loc 1 130 8
	nop	
.L26:
# boot.c:130:   while((uart_status[0] & 1)== 1) {};
	.loc 1 130 21 discriminator 1
	lui	a5,%hi(uart_status)	# tmp124,
	lw	a5,%lo(uart_status)(a5)		# uart_status.18_16, uart_status
	lbu	a5,0(a5)	# _17, *uart_status.18_16
# boot.c:130:   while((uart_status[0] & 1)== 1) {};
	.loc 1 130 25 discriminator 1
	andi	a5,a5,1	#, _19, _18
# boot.c:130:   while((uart_status[0] & 1)== 1) {};
	.loc 1 130 8 discriminator 1
	bne	a5,zero,.L26	#, _19,,
# boot.c:131:   sendchar('\n');
	.loc 1 131 3
	li	a0,10		#,
	call	sendchar		#
# boot.c:132:   while((uart_status[0] & 1)== 1) {};
	.loc 1 132 8
	nop	
.L27:
# boot.c:132:   while((uart_status[0] & 1)== 1) {};
	.loc 1 132 21 discriminator 1
	lui	a5,%hi(uart_status)	# tmp125,
	lw	a5,%lo(uart_status)(a5)		# uart_status.19_20, uart_status
	lbu	a5,0(a5)	# _21, *uart_status.19_20
# boot.c:132:   while((uart_status[0] & 1)== 1) {};
	.loc 1 132 25 discriminator 1
	andi	a5,a5,1	#, _23, _22
# boot.c:132:   while((uart_status[0] & 1)== 1) {};
	.loc 1 132 8 discriminator 1
	bne	a5,zero,.L27	#, _23,,
# boot.c:133:   led_state=4;
	.loc 1 133 12
	lui	a5,%hi(led_state)	# tmp126,
	li	a4,4		# tmp127,
	sb	a4,%lo(led_state)(a5)	# tmp127, led_state
# boot.c:134:   setled();
	.loc 1 134 3
	call	setled		#
# boot.c:135:   return 0;
	.loc 1 135 10
	li	a5,0		# _51,
# boot.c:136: }
	.loc 1 136 1
	mv	a0,a5	#, <retval>
	lw	ra,44(sp)		#,
	.cfi_restore 1
	lw	s0,40(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE9:
	.size	load, .-load
	.align	2
	.globl	run
	.type	run, @function
run:
.LFB10:
	.loc 1 138 42
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)	#,
	sw	s0,40(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)	# load_ram_base, load_ram_base
# boot.c:139:   pid =2;
	.loc 1 139 7
	lui	a5,%hi(pid)	# tmp74,
	li	a4,2		# tmp75,
	sw	a4,%lo(pid)(a5)	# tmp75, pid
# boot.c:140:   int  start = ((int*)load_ram_base)[6];
	.loc 1 140 8
	lw	a5,-36(s0)		# tmp76, load_ram_base
	lw	a5,24(a5)		# tmp77, MEM[(int *)load_ram_base_3(D) + 24B]
	sw	a5,-20(s0)	# tmp77, start
# boot.c:141:   int (*boot_main)(void) = (int (*)())(start);
	.loc 1 141 9
	lw	a5,-20(s0)		# tmp78, start
	sw	a5,-24(s0)	# tmp78, boot_main
# boot.c:142:   return boot_main();
	.loc 1 142 10
	lw	a5,-24(s0)		# tmp79, boot_main
	jalr	a5		# tmp79
.LVL0:
	mv	a5,a0	# _7,
# boot.c:143: }
	.loc 1 143 1
	mv	a0,a5	#, <retval>
	lw	ra,44(sp)		#,
	.cfi_restore 1
	lw	s0,40(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE10:
	.size	run, .-run
	.globl	__mulsi3
	.section	.rodata
	.align	2
.LC2:
	.string	".bss"
	.text
	.align	2
	.globl	getBssHeader
	.type	getBssHeader, @function
getBssHeader:
.LFB11:
	.loc 1 146 59
	.cfi_startproc
	addi	sp,sp,-80	#,,
	.cfi_def_cfa_offset 80
	sw	ra,76(sp)	#,
	sw	s0,72(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,80	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-68(s0)	# load_ram_base, load_ram_base
# boot.c:147:       Elf32_Ehdr * header = (Elf32_Ehdr *)load_ram_base;
	.loc 1 147 20
	lw	a5,-68(s0)		# tmp86, load_ram_base
	sw	a5,-28(s0)	# tmp86, header
# boot.c:148:       int e_shoff  = header->e_shoff;
	.loc 1 148 28
	lw	a5,-28(s0)		# tmp87, header
	lw	a5,32(a5)		# _1, header_17->e_shoff
# boot.c:148:       int e_shoff  = header->e_shoff;
	.loc 1 148 11
	sw	a5,-32(s0)	# _1, e_shoff
# boot.c:149:       int e_shnum  =  header->e_shnum;  
	.loc 1 149 29
	lw	a5,-28(s0)		# tmp88, header
	lhu	a5,48(a5)	# _2, header_17->e_shnum
# boot.c:149:       int e_shnum  =  header->e_shnum;  
	.loc 1 149 11
	sw	a5,-36(s0)	# _2, e_shnum
# boot.c:150:       int e_shentsize = header->e_shentsize;
	.loc 1 150 31
	lw	a5,-28(s0)		# tmp89, header
	lhu	a5,46(a5)	# _3, header_17->e_shentsize
# boot.c:150:       int e_shentsize = header->e_shentsize;
	.loc 1 150 11
	sw	a5,-40(s0)	# _3, e_shentsize
# boot.c:151:       int e_shstrndx = header->e_shstrndx;
	.loc 1 151 30
	lw	a5,-28(s0)		# tmp90, header
	lhu	a5,50(a5)	# _4, header_17->e_shstrndx
# boot.c:151:       int e_shstrndx = header->e_shstrndx;
	.loc 1 151 11
	sw	a5,-44(s0)	# _4, e_shstrndx
# boot.c:152:       unsigned char * spnt = load_ram_base+e_shoff;
	.loc 1 152 43
	lw	a5,-32(s0)		# e_shoff.20_5, e_shoff
# boot.c:152:       unsigned char * spnt = load_ram_base+e_shoff;
	.loc 1 152 23
	lw	a4,-68(s0)		# tmp92, load_ram_base
	add	a5,a4,a5	# e_shoff.20_5, tmp91, tmp92
	sw	a5,-20(s0)	# tmp91, spnt
# boot.c:154:       Elf32_Off string_st = ((Elf32_Shdr *)((e_shstrndx*e_shentsize)+spnt))->sh_offset;
	.loc 1 154 56
	lw	a1,-40(s0)		#, e_shentsize
	lw	a0,-44(s0)		#, e_shstrndx
	call	__mulsi3		#
	mv	a5,a0	# tmp93,
	mv	a4,a5	# _7, _6
# boot.c:154:       Elf32_Off string_st = ((Elf32_Shdr *)((e_shstrndx*e_shentsize)+spnt))->sh_offset;
	.loc 1 154 69
	lw	a5,-20(s0)		# tmp94, spnt
	add	a5,a5,a4	# _7, _8, tmp94
# boot.c:154:       Elf32_Off string_st = ((Elf32_Shdr *)((e_shstrndx*e_shentsize)+spnt))->sh_offset;
	.loc 1 154 17
	lw	a5,16(a5)		# tmp95, MEM[(struct Elf32_Shdr *)_8].sh_offset
	sw	a5,-48(s0)	# tmp95, string_st
.LBB4:
# boot.c:156:       for(int i=0;i<e_shnum;i++) {
	.loc 1 156 15
	sw	zero,-24(s0)	#, i
# boot.c:156:       for(int i=0;i<e_shnum;i++) {
	.loc 1 156 7
	j	.L33		#
.L36:
.LBB5:
# boot.c:157:           Elf32_Shdr * sh = (Elf32_Shdr *)spnt;
	.loc 1 157 24
	lw	a5,-20(s0)		# tmp96, spnt
	sw	a5,-52(s0)	# tmp96, sh
# boot.c:158:           char * name = (char*)(load_ram_base+string_st+(sh->sh_name));
	.loc 1 158 60
	lw	a5,-52(s0)		# tmp97, sh
	lw	a4,0(a5)		# _9, sh_27->sh_name
# boot.c:158:           char * name = (char*)(load_ram_base+string_st+(sh->sh_name));
	.loc 1 158 56
	lw	a5,-48(s0)		# tmp98, string_st
	add	a5,a4,a5	# tmp98, _10, _9
# boot.c:158:           char * name = (char*)(load_ram_base+string_st+(sh->sh_name));
	.loc 1 158 18
	lw	a4,-68(s0)		# tmp100, load_ram_base
	add	a5,a4,a5	# _10, tmp99, tmp100
	sw	a5,-56(s0)	# tmp99, name
# boot.c:159:           if(!strcmp(".bss",name)) {
	.loc 1 159 15
	lw	a1,-56(s0)		#, name
	lui	a5,%hi(.LC2)	# tmp101,
	addi	a0,a5,%lo(.LC2)	#, tmp101,
	call	strcmp		#
	mv	a5,a0	# _11,
# boot.c:159:           if(!strcmp(".bss",name)) {
	.loc 1 159 13
	bne	a5,zero,.L34	#, _11,,
# boot.c:160:               return sh;
	.loc 1 160 22
	lw	a5,-52(s0)		# _15, sh
	j	.L35		#
.L34:
# boot.c:162:           spnt = spnt+e_shentsize;
	.loc 1 162 22 discriminator 2
	lw	a5,-40(s0)		# e_shentsize.21_12, e_shentsize
# boot.c:162:           spnt = spnt+e_shentsize;
	.loc 1 162 16 discriminator 2
	lw	a4,-20(s0)		# tmp103, spnt
	add	a5,a4,a5	# e_shentsize.21_12, tmp102, tmp103
	sw	a5,-20(s0)	# tmp102, spnt
.LBE5:
# boot.c:156:       for(int i=0;i<e_shnum;i++) {
	.loc 1 156 30 discriminator 2
	lw	a5,-24(s0)		# tmp105, i
	addi	a5,a5,1	#, tmp104, tmp105
	sw	a5,-24(s0)	# tmp104, i
.L33:
# boot.c:156:       for(int i=0;i<e_shnum;i++) {
	.loc 1 156 7 discriminator 1
	lw	a4,-24(s0)		# tmp106, i
	lw	a5,-36(s0)		# tmp107, e_shnum
	blt	a4,a5,.L36	#, tmp106, tmp107,
.LBE4:
# boot.c:164:       return 0;
	.loc 1 164 14
	li	a5,0		# _15,
.L35:
# boot.c:165: }
	.loc 1 165 1
	mv	a0,a5	#, <retval>
	lw	ra,76(sp)		#,
	.cfi_restore 1
	lw	s0,72(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 80
	addi	sp,sp,80	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE11:
	.size	getBssHeader, .-getBssHeader
	.align	2
	.globl	readchar
	.type	readchar, @function
readchar:
.LFB12:
	.loc 1 167 17
	.cfi_startproc
	addi	sp,sp,-16	#,,
	.cfi_def_cfa_offset 16
	sw	s0,12(sp)	#,
	.cfi_offset 8, -4
	addi	s0,sp,16	#,,
	.cfi_def_cfa 8, 0
# boot.c:168:   while((uart_status[0] & 2) != 2) {};
	.loc 1 168 8
	nop	
.L38:
# boot.c:168:   while((uart_status[0] & 2) != 2) {};
	.loc 1 168 21 discriminator 1
	lui	a5,%hi(uart_status)	# tmp79,
	lw	a5,%lo(uart_status)(a5)		# uart_status.22_1, uart_status
	lbu	a5,0(a5)	# _2, *uart_status.22_1
# boot.c:168:   while((uart_status[0] & 2) != 2) {};
	.loc 1 168 25 discriminator 1
	andi	a5,a5,2	#, _4, _3
# boot.c:168:   while((uart_status[0] & 2) != 2) {};
	.loc 1 168 8 discriminator 1
	beq	a5,zero,.L38	#, _4,,
# boot.c:169:   return uart_in[0];
	.loc 1 169 17
	lui	a5,%hi(uart_in)	# tmp80,
	lw	a5,%lo(uart_in)(a5)		# uart_in.23_5, uart_in
	lbu	a5,0(a5)	# _7, *uart_in.23_5
# boot.c:170: }
	.loc 1 170 1
	mv	a0,a5	#, <retval>
	lw	s0,12(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE12:
	.size	readchar, .-readchar
	.section	.rodata
	.align	2
.LC3:
	.string	"\n"
	.text
	.align	2
	.globl	readline
	.type	readline, @function
readline:
.LFB13:
	.loc 1 172 34
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)	#,
	sw	s0,40(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)	# buf, buf
	sw	a1,-40(s0)	# max, max
# boot.c:173:   int pos = 0;
	.loc 1 173 7
	sw	zero,-20(s0)	#, pos
# boot.c:175:   while(pos < max-1) {
	.loc 1 175 8
	j	.L41		#
.L48:
# boot.c:176:     c = readchar();
	.loc 1 176 9
	call	readchar		#
	mv	a5,a0	# tmp80,
	sb	a5,-21(s0)	# tmp80, c
# boot.c:177:     if(c == '\r') break;
	.loc 1 177 7
	lbu	a4,-21(s0)	# tmp81, c
	li	a5,13		# tmp82,
	beq	a4,a5,.L50	#, tmp81, tmp82,
# boot.c:178:     if(c == '\n') break;
	.loc 1 178 7
	lbu	a4,-21(s0)	# tmp83, c
	li	a5,10		# tmp84,
	beq	a4,a5,.L51	#, tmp83, tmp84,
# boot.c:179:     if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
	.loc 1 179 7
	lbu	a4,-21(s0)	# tmp85, c
	li	a5,8		# tmp86,
	beq	a4,a5,.L45	#, tmp85, tmp86,
# boot.c:179:     if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
	.loc 1 179 15 discriminator 2
	lbu	a4,-21(s0)	# tmp87, c
	li	a5,127		# tmp88,
	bne	a4,a5,.L46	#, tmp87, tmp88,
.L45:
# boot.c:179:     if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
	.loc 1 179 32 discriminator 3
	lw	a5,-20(s0)		# tmp89, pos
	ble	a5,zero,.L41	#, tmp89,,
# boot.c:179:     if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
	.loc 1 179 43 discriminator 4
	lw	a5,-20(s0)		# tmp91, pos
	addi	a5,a5,-1	#, tmp90, tmp91
	sw	a5,-20(s0)	# tmp90, pos
# boot.c:179:     if(c == 8 || c == 127) { if(pos>0) pos--; continue; }
	.loc 1 179 5 discriminator 4
	j	.L41		#
.L46:
# boot.c:180:     buf[pos++] = c;
	.loc 1 180 12
	lw	a5,-20(s0)		# pos.24_1, pos
	addi	a4,a5,1	#, tmp92, pos.24_1
	sw	a4,-20(s0)	# tmp92, pos
	mv	a4,a5	# pos.25_2, pos.24_1
# boot.c:180:     buf[pos++] = c;
	.loc 1 180 8
	lw	a5,-36(s0)		# tmp93, buf
	add	a5,a5,a4	# pos.25_2, _3, tmp93
# boot.c:180:     buf[pos++] = c;
	.loc 1 180 16
	lbu	a4,-21(s0)	# tmp94, c
	sb	a4,0(a5)	# tmp94, *_3
# boot.c:181:     sendchar(c);
	.loc 1 181 5
	lbu	a5,-21(s0)	# tmp95, c
	mv	a0,a5	#, tmp95
	call	sendchar		#
.L41:
# boot.c:175:   while(pos < max-1) {
	.loc 1 175 18
	lw	a5,-40(s0)		# tmp96, max
	addi	a5,a5,-1	#, _4, tmp96
# boot.c:175:   while(pos < max-1) {
	.loc 1 175 8
	lw	a4,-20(s0)		# tmp97, pos
	blt	a4,a5,.L48	#, tmp97, _4,
	j	.L43		#
.L50:
# boot.c:177:     if(c == '\r') break;
	.loc 1 177 5
	nop	
	j	.L43		#
.L51:
# boot.c:178:     if(c == '\n') break;
	.loc 1 178 5
	nop	
.L43:
# boot.c:183:   buf[pos] = 0;
	.loc 1 183 6
	lw	a5,-20(s0)		# pos.26_5, pos
	lw	a4,-36(s0)		# tmp98, buf
	add	a5,a4,a5	# pos.26_5, _6, tmp98
# boot.c:183:   buf[pos] = 0;
	.loc 1 183 12
	sb	zero,0(a5)	#, *_6
# boot.c:184:   sendstring("\n");
	.loc 1 184 3
	lui	a5,%hi(.LC3)	# tmp99,
	addi	a0,a5,%lo(.LC3)	#, tmp99,
	call	sendstring		#
# boot.c:185:   return pos;
	.loc 1 185 10
	lw	a5,-20(s0)		# _23, pos
# boot.c:186: }
	.loc 1 186 1
	mv	a0,a5	#, <retval>
	lw	ra,44(sp)		#,
	.cfi_restore 1
	lw	s0,40(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE13:
	.size	readline, .-readline
	.section	.rodata
	.align	2
.LC4:
	.string	"ls: stub. No filesystem available.\n"
	.text
	.align	2
	.globl	ls_stub
	.type	ls_stub, @function
ls_stub:
.LFB14:
	.loc 1 188 16
	.cfi_startproc
	addi	sp,sp,-16	#,,
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)	#,
	sw	s0,8(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16	#,,
	.cfi_def_cfa 8, 0
# boot.c:189:   sendstring("ls: stub. No filesystem available.\n");
	.loc 1 189 3
	lui	a5,%hi(.LC4)	# tmp72,
	addi	a0,a5,%lo(.LC4)	#, tmp72,
	call	sendstring		#
# boot.c:190: }
	.loc 1 190 1
	nop	
	lw	ra,12(sp)		#,
	.cfi_restore 1
	lw	s0,8(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE14:
	.size	ls_stub, .-ls_stub
	.section	.rodata
	.align	2
.LC5:
	.string	"cd: stub, changed to "
	.text
	.align	2
	.globl	cd_stub
	.type	cd_stub, @function
cd_stub:
.LFB15:
	.loc 1 192 25
	.cfi_startproc
	addi	sp,sp,-32	#,,
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)	#,
	sw	s0,24(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)	# dir, dir
# boot.c:193:   sendstring("cd: stub, changed to ");
	.loc 1 193 3
	lui	a5,%hi(.LC5)	# tmp72,
	addi	a0,a5,%lo(.LC5)	#, tmp72,
	call	sendstring		#
# boot.c:194:   sendstring(dir);
	.loc 1 194 3
	lw	a0,-20(s0)		#, dir
	call	sendstring		#
# boot.c:195:   sendstring("\n");
	.loc 1 195 3
	lui	a5,%hi(.LC3)	# tmp73,
	addi	a0,a5,%lo(.LC3)	#, tmp73,
	call	sendstring		#
# boot.c:196: }
	.loc 1 196 1
	nop	
	lw	ra,28(sp)		#,
	.cfi_restore 1
	lw	s0,24(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE15:
	.size	cd_stub, .-cd_stub
	.section	.rodata
	.align	2
.LC6:
	.string	"run: stub, would run file: "
	.text
	.align	2
	.globl	run_file_stub
	.type	run_file_stub, @function
run_file_stub:
.LFB16:
	.loc 1 198 33
	.cfi_startproc
	addi	sp,sp,-32	#,,
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)	#,
	sw	s0,24(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32	#,,
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)	# fname, fname
# boot.c:199:   sendstring("run: stub, would run file: ");
	.loc 1 199 3
	lui	a5,%hi(.LC6)	# tmp72,
	addi	a0,a5,%lo(.LC6)	#, tmp72,
	call	sendstring		#
# boot.c:200:   sendstring(fname);
	.loc 1 200 3
	lw	a0,-20(s0)		#, fname
	call	sendstring		#
# boot.c:201:   sendstring("\n");
	.loc 1 201 3
	lui	a5,%hi(.LC3)	# tmp73,
	addi	a0,a5,%lo(.LC3)	#, tmp73,
	call	sendstring		#
# boot.c:202: }
	.loc 1 202 1
	nop	
	lw	ra,28(sp)		#,
	.cfi_restore 1
	lw	s0,24(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE16:
	.size	run_file_stub, .-run_file_stub
	.section	.rodata
	.align	2
.LC7:
	.string	"Waiting....\n"
	.align	2
.LC8:
	.string	"Load failure\n"
	.align	2
.LC9:
	.string	"Load complete\n"
	.align	2
.LC10:
	.string	"Filename = "
	.align	2
.LC11:
	.string	"File type program\n"
	.align	2
.LC12:
	.string	"Setting heap to  = "
	.align	2
.LC13:
	.string	"Finished\n"
	.align	2
.LC14:
	.string	"File type data\n"
	.text
	.align	2
	.globl	upload_loop
	.type	upload_loop, @function
upload_loop:
.LFB17:
	.loc 1 205 20
	.cfi_startproc
	addi	sp,sp,-48	#,,
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)	#,
	sw	s0,40(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48	#,,
	.cfi_def_cfa 8, 0
# boot.c:207:   unsigned char * load_ram_base= (unsigned char *)0x10000;
	.loc 1 207 19
	li	a5,65536		# tmp77,
	sw	a5,-20(s0)	# tmp77, load_ram_base
.L59:
# boot.c:210:     sendstring("Waiting....\n");
	.loc 1 210 5
	lui	a5,%hi(.LC7)	# tmp78,
	addi	a0,a5,%lo(.LC7)	#, tmp78,
	call	sendstring		#
# boot.c:211:     if(load()) {
	.loc 1 211 8
	call	load		#
	mv	a5,a0	# _1,
# boot.c:211:     if(load()) {
	.loc 1 211 7
	beq	a5,zero,.L56	#, _1,,
# boot.c:212:         sendstring("Load failure\n");
	.loc 1 212 9
	lui	a5,%hi(.LC8)	# tmp79,
	addi	a0,a5,%lo(.LC8)	#, tmp79,
	call	sendstring		#
	j	.L59		#
.L56:
# boot.c:214:         sendstring("Load complete\n");
	.loc 1 214 9
	lui	a5,%hi(.LC9)	# tmp80,
	addi	a0,a5,%lo(.LC9)	#, tmp80,
	call	sendstring		#
# boot.c:215:         sendstring("Filename = ");
	.loc 1 215 9
	lui	a5,%hi(.LC10)	# tmp81,
	addi	a0,a5,%lo(.LC10)	#, tmp81,
	call	sendstring		#
# boot.c:216:         sendstring(fileHeader.name);
	.loc 1 216 9
	lui	a5,%hi(fileHeader+1)	# tmp82,
	addi	a0,a5,%lo(fileHeader+1)	#, tmp82,
	call	sendstring		#
# boot.c:217:         sendstring("\n");
	.loc 1 217 9
	lui	a5,%hi(.LC3)	# tmp83,
	addi	a0,a5,%lo(.LC3)	#, tmp83,
	call	sendstring		#
# boot.c:218:         if(fileHeader.type==0) {
	.loc 1 218 22
	lui	a5,%hi(fileHeader)	# tmp84,
	addi	a5,a5,%lo(fileHeader)	# tmp85, tmp84,
	lbu	a5,0(a5)	# _2, fileHeader.type
# boot.c:218:         if(fileHeader.type==0) {
	.loc 1 218 11
	bne	a5,zero,.L58	#, _2,,
.LBB6:
# boot.c:219:           Elf32_Shdr * bssHeader = getBssHeader(load_ram_base);
	.loc 1 219 36
	lw	a0,-20(s0)		#, load_ram_base
	call	getBssHeader		#
	sw	a0,-24(s0)	#, bssHeader
# boot.c:220:           sendstring("File type program\n");
	.loc 1 220 11
	lui	a5,%hi(.LC11)	# tmp86,
	addi	a0,a5,%lo(.LC11)	#, tmp86,
	call	sendstring		#
# boot.c:221:           itoa((int)(load_ram_base+bssHeader->sh_offset), temp, 16);
	.loc 1 221 45
	lw	a5,-24(s0)		# tmp87, bssHeader
	lw	a5,16(a5)		# _3, bssHeader_18->sh_offset
# boot.c:221:           itoa((int)(load_ram_base+bssHeader->sh_offset), temp, 16);
	.loc 1 221 35
	lw	a4,-20(s0)		# tmp88, load_ram_base
	add	a5,a4,a5	# _3, _4, tmp88
# boot.c:221:           itoa((int)(load_ram_base+bssHeader->sh_offset), temp, 16);
	.loc 1 221 11
	mv	a4,a5	# _5, _4
	addi	a5,s0,-40	#, tmp89,
	li	a2,16		#,
	mv	a1,a5	#, tmp89
	mv	a0,a4	#, _5
	call	itoa		#
# boot.c:222:           sendstring("Setting heap to  = ");
	.loc 1 222 11
	lui	a5,%hi(.LC12)	# tmp90,
	addi	a0,a5,%lo(.LC12)	#, tmp90,
	call	sendstring		#
# boot.c:223:           sendstring(temp);
	.loc 1 223 11
	addi	a5,s0,-40	#, tmp91,
	mv	a0,a5	#, tmp91
	call	sendstring		#
# boot.c:224:           sendstring("\n");
	.loc 1 224 11
	lui	a5,%hi(.LC3)	# tmp92,
	addi	a0,a5,%lo(.LC3)	#, tmp92,
	call	sendstring		#
# boot.c:225:           run(load_ram_base);
	.loc 1 225 11
	lw	a0,-20(s0)		#, load_ram_base
	call	run		#
# boot.c:226:           sendstring("Finished\n");
	.loc 1 226 11
	lui	a5,%hi(.LC13)	# tmp93,
	addi	a0,a5,%lo(.LC13)	#, tmp93,
	call	sendstring		#
.LBE6:
	j	.L59		#
.L58:
# boot.c:228:           sendstring("File type data\n");
	.loc 1 228 11
	lui	a5,%hi(.LC14)	# tmp94,
	addi	a0,a5,%lo(.LC14)	#, tmp94,
	call	sendstring		#
# boot.c:210:     sendstring("Waiting....\n");
	.loc 1 210 5
	j	.L59		#
	.cfi_endproc
.LFE17:
	.size	upload_loop, .-upload_loop
	.section	.rodata
	.align	2
.LC15:
	.string	"CRISC-V Bootloader v0.2 - RV32I\n"
	.align	2
.LC16:
	.string	"> "
	.align	2
.LC17:
	.string	" "
	.align	2
.LC18:
	.string	"ls"
	.align	2
.LC19:
	.string	"cd"
	.align	2
.LC20:
	.string	"cd: missing argument\n"
	.align	2
.LC21:
	.string	"run"
	.align	2
.LC22:
	.string	"run: missing filename\n"
	.align	2
.LC23:
	.string	"upload"
	.align	2
.LC24:
	.string	"help"
	.align	2
.LC25:
	.string	"Commands: ls cd run upload help\n"
	.align	2
.LC26:
	.string	"Unknown command\n"
	.text
	.align	2
	.globl	shell
	.type	shell, @function
shell:
.LFB18:
	.loc 1 234 14
	.cfi_startproc
	addi	sp,sp,-160	#,,
	.cfi_def_cfa_offset 160
	sw	ra,156(sp)	#,
	sw	s0,152(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,160	#,,
	.cfi_def_cfa 8, 0
# boot.c:236:   sendstring("CRISC-V Bootloader v0.2 - RV32I\n");
	.loc 1 236 3
	lui	a5,%hi(.LC15)	# tmp77,
	addi	a0,a5,%lo(.LC15)	#, tmp77,
	call	sendstring		#
.L70:
.LBB7:
# boot.c:239:     sendstring("> ");
	.loc 1 239 5
	lui	a5,%hi(.LC16)	# tmp78,
	addi	a0,a5,%lo(.LC16)	#, tmp78,
	call	sendstring		#
# boot.c:240:     readline(buf, sizeof(buf));
	.loc 1 240 5
	addi	a5,s0,-156	#, tmp79,
	li	a1,128		#,
	mv	a0,a5	#, tmp79
	call	readline		#
# boot.c:241:     char *cmd = strtok(buf, " ");
	.loc 1 241 17
	addi	a4,s0,-156	#, tmp80,
	lui	a5,%hi(.LC17)	# tmp81,
	addi	a1,a5,%lo(.LC17)	#, tmp81,
	mv	a0,a4	#, tmp80
	call	strtok		#
	sw	a0,-20(s0)	#, cmd
# boot.c:242:     if(!cmd) continue;
	.loc 1 242 7
	lw	a5,-20(s0)		# tmp82, cmd
	beq	a5,zero,.L71	#, tmp82,,
# boot.c:243:     if(!strcmp(cmd, "ls")) {
	.loc 1 243 9
	lui	a5,%hi(.LC18)	# tmp83,
	addi	a1,a5,%lo(.LC18)	#, tmp83,
	lw	a0,-20(s0)		#, cmd
	call	strcmp		#
	mv	a5,a0	# _1,
# boot.c:243:     if(!strcmp(cmd, "ls")) {
	.loc 1 243 7
	bne	a5,zero,.L63	#, _1,,
# boot.c:244:       ls_stub();
	.loc 1 244 7
	call	ls_stub		#
	j	.L70		#
.L63:
# boot.c:245:     } else if(!strcmp(cmd, "cd")) {
	.loc 1 245 16
	lui	a5,%hi(.LC19)	# tmp84,
	addi	a1,a5,%lo(.LC19)	#, tmp84,
	lw	a0,-20(s0)		#, cmd
	call	strcmp		#
	mv	a5,a0	# _2,
# boot.c:245:     } else if(!strcmp(cmd, "cd")) {
	.loc 1 245 14
	bne	a5,zero,.L64	#, _2,,
.LBB8:
# boot.c:246:       char *arg = strtok(NULL, " ");
	.loc 1 246 19
	lui	a5,%hi(.LC17)	# tmp85,
	addi	a1,a5,%lo(.LC17)	#, tmp85,
	li	a0,0		#,
	call	strtok		#
	sw	a0,-28(s0)	#, arg
# boot.c:247:       if(arg) cd_stub(arg); else sendstring("cd: missing argument\n");
	.loc 1 247 9
	lw	a5,-28(s0)		# tmp86, arg
	beq	a5,zero,.L65	#, tmp86,,
# boot.c:247:       if(arg) cd_stub(arg); else sendstring("cd: missing argument\n");
	.loc 1 247 15 discriminator 1
	lw	a0,-28(s0)		#, arg
	call	cd_stub		#
	j	.L70		#
.L65:
# boot.c:247:       if(arg) cd_stub(arg); else sendstring("cd: missing argument\n");
	.loc 1 247 34 discriminator 2
	lui	a5,%hi(.LC20)	# tmp87,
	addi	a0,a5,%lo(.LC20)	#, tmp87,
	call	sendstring		#
	j	.L70		#
.L64:
.LBE8:
# boot.c:248:     } else if(!strcmp(cmd, "run")) {
	.loc 1 248 16
	lui	a5,%hi(.LC21)	# tmp88,
	addi	a1,a5,%lo(.LC21)	#, tmp88,
	lw	a0,-20(s0)		#, cmd
	call	strcmp		#
	mv	a5,a0	# _3,
# boot.c:248:     } else if(!strcmp(cmd, "run")) {
	.loc 1 248 14
	bne	a5,zero,.L66	#, _3,,
.LBB9:
# boot.c:249:       char *arg = strtok(NULL, " ");
	.loc 1 249 19
	lui	a5,%hi(.LC17)	# tmp89,
	addi	a1,a5,%lo(.LC17)	#, tmp89,
	li	a0,0		#,
	call	strtok		#
	sw	a0,-24(s0)	#, arg
# boot.c:250:       if(arg) run_file_stub(arg); else sendstring("run: missing filename\n");
	.loc 1 250 9
	lw	a5,-24(s0)		# tmp90, arg
	beq	a5,zero,.L67	#, tmp90,,
# boot.c:250:       if(arg) run_file_stub(arg); else sendstring("run: missing filename\n");
	.loc 1 250 15 discriminator 1
	lw	a0,-24(s0)		#, arg
	call	run_file_stub		#
	j	.L70		#
.L67:
# boot.c:250:       if(arg) run_file_stub(arg); else sendstring("run: missing filename\n");
	.loc 1 250 40 discriminator 2
	lui	a5,%hi(.LC22)	# tmp91,
	addi	a0,a5,%lo(.LC22)	#, tmp91,
	call	sendstring		#
	j	.L70		#
.L66:
.LBE9:
# boot.c:251:     } else if(!strcmp(cmd, "upload")) {
	.loc 1 251 16
	lui	a5,%hi(.LC23)	# tmp92,
	addi	a1,a5,%lo(.LC23)	#, tmp92,
	lw	a0,-20(s0)		#, cmd
	call	strcmp		#
	mv	a5,a0	# _4,
# boot.c:251:     } else if(!strcmp(cmd, "upload")) {
	.loc 1 251 14
	bne	a5,zero,.L68	#, _4,,
# boot.c:252:       upload_loop();
	.loc 1 252 7
	call	upload_loop		#
	j	.L70		#
.L68:
# boot.c:253:     } else if(!strcmp(cmd, "help")) {
	.loc 1 253 16
	lui	a5,%hi(.LC24)	# tmp93,
	addi	a1,a5,%lo(.LC24)	#, tmp93,
	lw	a0,-20(s0)		#, cmd
	call	strcmp		#
	mv	a5,a0	# _5,
# boot.c:253:     } else if(!strcmp(cmd, "help")) {
	.loc 1 253 14
	bne	a5,zero,.L69	#, _5,,
# boot.c:254:       sendstring("Commands: ls cd run upload help\n");
	.loc 1 254 7
	lui	a5,%hi(.LC25)	# tmp94,
	addi	a0,a5,%lo(.LC25)	#, tmp94,
	call	sendstring		#
	j	.L70		#
.L69:
# boot.c:256:       sendstring("Unknown command\n");
	.loc 1 256 7
	lui	a5,%hi(.LC26)	# tmp95,
	addi	a0,a5,%lo(.LC26)	#, tmp95,
	call	sendstring		#
	j	.L70		#
.L71:
# boot.c:242:     if(!cmd) continue;
	.loc 1 242 5
	nop	
.LBE7:
# boot.c:238:   while(1) {
	.loc 1 238 12
	j	.L70		#
	.cfi_endproc
.LFE18:
	.size	shell, .-shell
	.section	.rodata
	.align	2
.LC27:
	.string	"CRISC-V Bootloader v0.2\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB19:
	.loc 1 261 12
	.cfi_startproc
	addi	sp,sp,-96	#,,
	.cfi_def_cfa_offset 96
	sw	ra,92(sp)	#,
	sw	s0,88(sp)	#,
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,96	#,,
	.cfi_def_cfa 8, 0
# boot.c:263:  led[0] = 1;
	.loc 1 263 5
	lui	a5,%hi(led)	# tmp76,
	lw	a5,%lo(led)(a5)		# led.27_1, led
# boot.c:263:  led[0] = 1;
	.loc 1 263 9
	li	a4,1		# tmp77,
	sb	a4,0(a5)	# tmp77, *led.27_1
# boot.c:265:   pid=1;
	.loc 1 265 6
	lui	a5,%hi(pid)	# tmp78,
	li	a4,1		# tmp79,
	sw	a4,%lo(pid)(a5)	# tmp79, pid
.LBB10:
# boot.c:268:   for(int i=0;i<16;i++) {
	.loc 1 268 11
	sw	zero,-20(s0)	#, i
# boot.c:268:   for(int i=0;i<16;i++) {
	.loc 1 268 3
	j	.L73		#
.L76:
.LBB11:
# boot.c:269:     for(int x=0;x<10000;x++) {
	.loc 1 269 13
	sw	zero,-24(s0)	#, x
# boot.c:269:     for(int x=0;x<10000;x++) {
	.loc 1 269 5
	j	.L74		#
.L75:
# boot.c:269:     for(int x=0;x<10000;x++) {
	.loc 1 269 26 discriminator 3
	lw	a5,-24(s0)		# tmp81, x
	addi	a5,a5,1	#, tmp80, tmp81
	sw	a5,-24(s0)	# tmp80, x
.L74:
# boot.c:269:     for(int x=0;x<10000;x++) {
	.loc 1 269 5 discriminator 1
	lw	a4,-24(s0)		# tmp84, x
	li	a5,8192		# tmp86,
	addi	a5,a5,1807	#, tmp85, tmp86
	ble	a4,a5,.L75	#, tmp84, tmp85,
.LBE11:
# boot.c:274:     led_state=i;
	.loc 1 274 14 discriminator 2
	lw	a5,-20(s0)		# tmp87, i
	andi	a4,a5,0xff	# _2, tmp87
	lui	a5,%hi(led_state)	# tmp88,
	sb	a4,%lo(led_state)(a5)	# _2, led_state
# boot.c:275:     setled();
	.loc 1 275 5 discriminator 2
	call	setled		#
# boot.c:268:   for(int i=0;i<16;i++) {
	.loc 1 268 21 discriminator 2
	lw	a5,-20(s0)		# tmp90, i
	addi	a5,a5,1	#, tmp89, tmp90
	sw	a5,-20(s0)	# tmp89, i
.L73:
# boot.c:268:   for(int i=0;i<16;i++) {
	.loc 1 268 3 discriminator 1
	lw	a4,-20(s0)		# tmp91, i
	li	a5,15		# tmp92,
	ble	a4,a5,.L76	#, tmp91, tmp92,
.LBE10:
# boot.c:279:   sendstring("CRISC-V Bootloader v0.2\n");
	.loc 1 279 3
	lui	a5,%hi(.LC27)	# tmp93,
	addi	a0,a5,%lo(.LC27)	#, tmp93,
	call	sendstring		#
# boot.c:290:   shell();
	.loc 1 290 3
	call	shell		#
# boot.c:291:   return 0;
	.loc 1 291 10
	li	a5,0		# _12,
# boot.c:292: }
	.loc 1 292 1
	mv	a0,a5	#, <retval>
	lw	ra,92(sp)		#,
	.cfi_restore 1
	lw	s0,88(sp)		#,
	.cfi_restore 8
	.cfi_def_cfa 2, 96
	addi	sp,sp,96	#,,
	.cfi_def_cfa_offset 0
	jr	ra		#
	.cfi_endproc
.LFE19:
	.size	main, .-main
.Letext0:
	.file 2 "/opt/riscv/riscv64-unknown-elf/include/machine/_default_types.h"
	.file 3 "/opt/riscv/riscv64-unknown-elf/include/sys/_stdint.h"
	.file 4 "/opt/riscv/riscv64-unknown-elf/include/elf.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0x802
	.2byte	0x4
	.4byte	.Ldebug_abbrev0
	.byte	0x4
	.byte	0x1
	.4byte	.LASF82
	.byte	0xc
	.4byte	.LASF83
	.4byte	.LASF84
	.4byte	.Ltext0
	.4byte	.Letext0-.Ltext0
	.4byte	.Ldebug_line0
	.byte	0x2
	.byte	0x1
	.byte	0x6
	.4byte	.LASF0
	.byte	0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF1
	.byte	0x2
	.byte	0x2
	.byte	0x5
	.4byte	.LASF2
	.byte	0x3
	.4byte	.LASF5
	.byte	0x2
	.byte	0x39
	.byte	0x19
	.4byte	0x46
	.byte	0x2
	.byte	0x2
	.byte	0x7
	.4byte	.LASF3
	.byte	0x2
	.byte	0x4
	.byte	0x5
	.4byte	.LASF4
	.byte	0x3
	.4byte	.LASF6
	.byte	0x2
	.byte	0x4f
	.byte	0x19
	.4byte	0x60
	.byte	0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF7
	.byte	0x2
	.byte	0x8
	.byte	0x5
	.4byte	.LASF8
	.byte	0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF9
	.byte	0x4
	.byte	0x4
	.byte	0x5
	.string	"int"
	.byte	0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF10
	.byte	0x2
	.byte	0x10
	.byte	0x4
	.4byte	.LASF11
	.byte	0x3
	.4byte	.LASF12
	.byte	0x3
	.byte	0x24
	.byte	0x14
	.4byte	0x3a
	.byte	0x3
	.4byte	.LASF13
	.byte	0x3
	.byte	0x30
	.byte	0x14
	.4byte	0x54
	.byte	0x5
	.byte	0x4
	.4byte	0xa8
	.byte	0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF14
	.byte	0x5
	.byte	0x4
	.4byte	0x2c
	.byte	0x3
	.4byte	.LASF15
	.byte	0x4
	.byte	0x23
	.byte	0x12
	.4byte	0x8a
	.byte	0x3
	.4byte	.LASF16
	.byte	0x4
	.byte	0x26
	.byte	0x12
	.4byte	0x96
	.byte	0x3
	.4byte	.LASF17
	.byte	0x4
	.byte	0x30
	.byte	0x12
	.4byte	0x96
	.byte	0x3
	.4byte	.LASF18
	.byte	0x4
	.byte	0x33
	.byte	0x12
	.4byte	0x96
	.byte	0x6
	.byte	0x34
	.byte	0x4
	.byte	0x3e
	.byte	0x9
	.4byte	0x1a5
	.byte	0x7
	.4byte	.LASF19
	.byte	0x4
	.byte	0x3f
	.byte	0x11
	.4byte	0x1a5
	.byte	0
	.byte	0x7
	.4byte	.LASF20
	.byte	0x4
	.byte	0x40
	.byte	0xe
	.4byte	0xb5
	.byte	0x10
	.byte	0x7
	.4byte	.LASF21
	.byte	0x4
	.byte	0x41
	.byte	0xe
	.4byte	0xb5
	.byte	0x12
	.byte	0x7
	.4byte	.LASF22
	.byte	0x4
	.byte	0x42
	.byte	0xe
	.4byte	0xc1
	.byte	0x14
	.byte	0x7
	.4byte	.LASF23
	.byte	0x4
	.byte	0x43
	.byte	0xe
	.4byte	0xcd
	.byte	0x18
	.byte	0x7
	.4byte	.LASF24
	.byte	0x4
	.byte	0x44
	.byte	0xd
	.4byte	0xd9
	.byte	0x1c
	.byte	0x7
	.4byte	.LASF25
	.byte	0x4
	.byte	0x45
	.byte	0xd
	.4byte	0xd9
	.byte	0x20
	.byte	0x7
	.4byte	.LASF26
	.byte	0x4
	.byte	0x46
	.byte	0xe
	.4byte	0xc1
	.byte	0x24
	.byte	0x7
	.4byte	.LASF27
	.byte	0x4
	.byte	0x47
	.byte	0xe
	.4byte	0xb5
	.byte	0x28
	.byte	0x7
	.4byte	.LASF28
	.byte	0x4
	.byte	0x48
	.byte	0xe
	.4byte	0xb5
	.byte	0x2a
	.byte	0x7
	.4byte	.LASF29
	.byte	0x4
	.byte	0x49
	.byte	0xe
	.4byte	0xb5
	.byte	0x2c
	.byte	0x7
	.4byte	.LASF30
	.byte	0x4
	.byte	0x4a
	.byte	0xe
	.4byte	0xb5
	.byte	0x2e
	.byte	0x7
	.4byte	.LASF31
	.byte	0x4
	.byte	0x4b
	.byte	0xe
	.4byte	0xb5
	.byte	0x30
	.byte	0x7
	.4byte	.LASF32
	.byte	0x4
	.byte	0x4c
	.byte	0xe
	.4byte	0xb5
	.byte	0x32
	.byte	0
	.byte	0x8
	.4byte	0x2c
	.4byte	0x1b5
	.byte	0x9
	.4byte	0x7c
	.byte	0xf
	.byte	0
	.byte	0x3
	.4byte	.LASF33
	.byte	0x4
	.byte	0x4d
	.byte	0x3
	.4byte	0xe5
	.byte	0xa
	.byte	0x28
	.byte	0x4
	.2byte	0x15e
	.byte	0x9
	.4byte	0x258
	.byte	0xb
	.4byte	.LASF34
	.byte	0x4
	.2byte	0x15f
	.byte	0xe
	.4byte	0xc1
	.byte	0
	.byte	0xb
	.4byte	.LASF35
	.byte	0x4
	.2byte	0x160
	.byte	0xe
	.4byte	0xc1
	.byte	0x4
	.byte	0xb
	.4byte	.LASF36
	.byte	0x4
	.2byte	0x161
	.byte	0xe
	.4byte	0xc1
	.byte	0x8
	.byte	0xb
	.4byte	.LASF37
	.byte	0x4
	.2byte	0x162
	.byte	0xe
	.4byte	0xcd
	.byte	0xc
	.byte	0xb
	.4byte	.LASF38
	.byte	0x4
	.2byte	0x163
	.byte	0xd
	.4byte	0xd9
	.byte	0x10
	.byte	0xb
	.4byte	.LASF39
	.byte	0x4
	.2byte	0x164
	.byte	0xe
	.4byte	0xc1
	.byte	0x14
	.byte	0xb
	.4byte	.LASF40
	.byte	0x4
	.2byte	0x165
	.byte	0xe
	.4byte	0xc1
	.byte	0x18
	.byte	0xb
	.4byte	.LASF41
	.byte	0x4
	.2byte	0x166
	.byte	0xe
	.4byte	0xc1
	.byte	0x1c
	.byte	0xb
	.4byte	.LASF42
	.byte	0x4
	.2byte	0x167
	.byte	0xe
	.4byte	0xc1
	.byte	0x20
	.byte	0xb
	.4byte	.LASF43
	.byte	0x4
	.2byte	0x168
	.byte	0xe
	.4byte	0xc1
	.byte	0x24
	.byte	0
	.byte	0xc
	.4byte	.LASF44
	.byte	0x4
	.2byte	0x169
	.byte	0x3
	.4byte	0x1c1
	.byte	0xd
	.4byte	.LASF48
	.byte	0x1c
	.byte	0x1
	.byte	0xd
	.byte	0x8
	.4byte	0x29a
	.byte	0x7
	.4byte	.LASF45
	.byte	0x1
	.byte	0xe
	.byte	0xa
	.4byte	0xa8
	.byte	0
	.byte	0x7
	.4byte	.LASF46
	.byte	0x1
	.byte	0xf
	.byte	0xa
	.4byte	0x29a
	.byte	0x1
	.byte	0x7
	.4byte	.LASF47
	.byte	0x1
	.byte	0x10
	.byte	0xd
	.4byte	0x96
	.byte	0x18
	.byte	0
	.byte	0x8
	.4byte	0xa8
	.4byte	0x2aa
	.byte	0x9
	.4byte	0x7c
	.byte	0x13
	.byte	0
	.byte	0xe
	.4byte	.LASF48
	.byte	0x1
	.byte	0x11
	.byte	0x3
	.4byte	0x265
	.byte	0x5
	.byte	0x3
	.4byte	FileHeader
	.byte	0xe
	.4byte	.LASF49
	.byte	0x1
	.byte	0x14
	.byte	0x6
	.4byte	0xa8
	.byte	0x5
	.byte	0x3
	.4byte	led_state
	.byte	0xf
	.string	"led"
	.byte	0x1
	.byte	0x15
	.byte	0x8
	.4byte	0xa2
	.byte	0x5
	.byte	0x3
	.4byte	led
	.byte	0xe
	.4byte	.LASF50
	.byte	0x1
	.byte	0x16
	.byte	0x8
	.4byte	0xa2
	.byte	0x5
	.byte	0x3
	.4byte	uart
	.byte	0xe
	.4byte	.LASF51
	.byte	0x1
	.byte	0x17
	.byte	0x8
	.4byte	0xa2
	.byte	0x5
	.byte	0x3
	.4byte	uart_status
	.byte	0xe
	.4byte	.LASF52
	.byte	0x1
	.byte	0x18
	.byte	0x8
	.4byte	0xa2
	.byte	0x5
	.byte	0x3
	.4byte	uart_in
	.byte	0x10
	.string	"pid"
	.byte	0x1
	.byte	0x1b
	.byte	0xc
	.4byte	0x75
	.byte	0xe
	.4byte	.LASF53
	.byte	0x1
	.byte	0x1d
	.byte	0x5
	.4byte	0x75
	.byte	0x5
	.byte	0x3
	.4byte	ftype
	.byte	0xe
	.4byte	.LASF54
	.byte	0x1
	.byte	0x50
	.byte	0x15
	.4byte	0x265
	.byte	0x5
	.byte	0x3
	.4byte	fileHeader
	.byte	0x11
	.4byte	.LASF61
	.byte	0x1
	.2byte	0x105
	.byte	0x5
	.4byte	0x75
	.4byte	.LFB19
	.4byte	.LFE19-.LFB19
	.byte	0x1
	.byte	0x9c
	.4byte	0x3a3
	.byte	0x12
	.4byte	.LASF55
	.byte	0x1
	.2byte	0x10b
	.byte	0xa
	.4byte	0x3a3
	.byte	0x3
	.byte	0x91
	.byte	0xa8,0x7f
	.byte	0x13
	.4byte	.LBB10
	.4byte	.LBE10-.LBB10
	.byte	0x14
	.string	"i"
	.byte	0x1
	.2byte	0x10c
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x13
	.4byte	.LBB11
	.4byte	.LBE11-.LBB11
	.byte	0x14
	.string	"x"
	.byte	0x1
	.2byte	0x10d
	.byte	0xd
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0
	.byte	0
	.byte	0x8
	.4byte	0x3b3
	.4byte	0x3b3
	.byte	0x9
	.4byte	0x7c
	.byte	0xf
	.byte	0
	.byte	0x5
	.byte	0x4
	.4byte	0x3b9
	.byte	0x15
	.4byte	0x3c0
	.byte	0x16
	.byte	0
	.byte	0x17
	.4byte	.LASF56
	.byte	0x1
	.byte	0xea
	.byte	0x6
	.4byte	.LFB18
	.4byte	.LFE18-.LFB18
	.byte	0x1
	.byte	0x9c
	.4byte	0x436
	.byte	0x18
	.string	"buf"
	.byte	0x1
	.byte	0xeb
	.byte	0x8
	.4byte	0x436
	.byte	0x3
	.byte	0x91
	.byte	0xe4,0x7e
	.byte	0x13
	.4byte	.LBB7
	.4byte	.LBE7-.LBB7
	.byte	0x18
	.string	"cmd"
	.byte	0x1
	.byte	0xf1
	.byte	0xb
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x19
	.4byte	.LBB8
	.4byte	.LBE8-.LBB8
	.4byte	0x41b
	.byte	0x18
	.string	"arg"
	.byte	0x1
	.byte	0xf6
	.byte	0xd
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x64
	.byte	0
	.byte	0x13
	.4byte	.LBB9
	.4byte	.LBE9-.LBB9
	.byte	0x18
	.string	"arg"
	.byte	0x1
	.byte	0xf9
	.byte	0xd
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0
	.byte	0
	.byte	0x8
	.4byte	0xa8
	.4byte	0x446
	.byte	0x9
	.4byte	0x7c
	.byte	0x7f
	.byte	0
	.byte	0x17
	.4byte	.LASF57
	.byte	0x1
	.byte	0xcd
	.byte	0x6
	.4byte	.LFB17
	.4byte	.LFE17-.LFB17
	.byte	0x1
	.byte	0x9c
	.4byte	0x494
	.byte	0x1a
	.4byte	.LASF58
	.byte	0x1
	.byte	0xce
	.byte	0x8
	.4byte	0x494
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x1a
	.4byte	.LASF59
	.byte	0x1
	.byte	0xcf
	.byte	0x13
	.4byte	0xaf
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x13
	.4byte	.LBB6
	.4byte	.LBE6-.LBB6
	.byte	0x1a
	.4byte	.LASF60
	.byte	0x1
	.byte	0xdb
	.byte	0x18
	.4byte	0x4a4
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0
	.byte	0x8
	.4byte	0xa8
	.4byte	0x4a4
	.byte	0x9
	.4byte	0x7c
	.byte	0xf
	.byte	0
	.byte	0x5
	.byte	0x4
	.4byte	0x258
	.byte	0x1b
	.4byte	.LASF62
	.byte	0x1
	.byte	0xc6
	.byte	0x6
	.4byte	.LFB16
	.4byte	.LFE16-.LFB16
	.byte	0x1
	.byte	0x9c
	.4byte	0x4d0
	.byte	0x1c
	.4byte	.LASF64
	.byte	0x1
	.byte	0xc6
	.byte	0x1a
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x1b
	.4byte	.LASF63
	.byte	0x1
	.byte	0xc0
	.byte	0x6
	.4byte	.LFB15
	.4byte	.LFE15-.LFB15
	.byte	0x1
	.byte	0x9c
	.4byte	0x4f6
	.byte	0x1d
	.string	"dir"
	.byte	0x1
	.byte	0xc0
	.byte	0x14
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x1e
	.4byte	.LASF80
	.byte	0x1
	.byte	0xbc
	.byte	0x6
	.4byte	.LFB14
	.4byte	.LFE14-.LFB14
	.byte	0x1
	.byte	0x9c
	.byte	0x1f
	.4byte	.LASF65
	.byte	0x1
	.byte	0xac
	.byte	0x5
	.4byte	0x75
	.4byte	.LFB13
	.4byte	.LFE13-.LFB13
	.byte	0x1
	.byte	0x9c
	.4byte	0x55d
	.byte	0x1d
	.string	"buf"
	.byte	0x1
	.byte	0xac
	.byte	0x14
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x1d
	.string	"max"
	.byte	0x1
	.byte	0xac
	.byte	0x1d
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x18
	.string	"pos"
	.byte	0x1
	.byte	0xad
	.byte	0x7
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x18
	.string	"c"
	.byte	0x1
	.byte	0xae
	.byte	0x8
	.4byte	0xa8
	.byte	0x2
	.byte	0x91
	.byte	0x6b
	.byte	0
	.byte	0x20
	.4byte	.LASF85
	.byte	0x1
	.byte	0xa7
	.byte	0x6
	.4byte	0xa8
	.4byte	.LFB12
	.4byte	.LFE12-.LFB12
	.byte	0x1
	.byte	0x9c
	.byte	0x1f
	.4byte	.LASF66
	.byte	0x1
	.byte	0x92
	.byte	0xf
	.4byte	0x4a4
	.4byte	.LFB11
	.4byte	.LFE11-.LFB11
	.byte	0x1
	.byte	0x9c
	.4byte	0x645
	.byte	0x1c
	.4byte	.LASF59
	.byte	0x1
	.byte	0x92
	.byte	0x2c
	.4byte	0xaf
	.byte	0x3
	.byte	0x91
	.byte	0xbc,0x7f
	.byte	0x1a
	.4byte	.LASF67
	.byte	0x1
	.byte	0x93
	.byte	0x14
	.4byte	0x645
	.byte	0x2
	.byte	0x91
	.byte	0x64
	.byte	0x1a
	.4byte	.LASF25
	.byte	0x1
	.byte	0x94
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x60
	.byte	0x1a
	.4byte	.LASF31
	.byte	0x1
	.byte	0x95
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x1a
	.4byte	.LASF30
	.byte	0x1
	.byte	0x96
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x1a
	.4byte	.LASF32
	.byte	0x1
	.byte	0x97
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x54
	.byte	0x1a
	.4byte	.LASF68
	.byte	0x1
	.byte	0x98
	.byte	0x17
	.4byte	0xaf
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x1a
	.4byte	.LASF69
	.byte	0x1
	.byte	0x9a
	.byte	0x11
	.4byte	0xd9
	.byte	0x2
	.byte	0x91
	.byte	0x50
	.byte	0x13
	.4byte	.LBB4
	.4byte	.LBE4-.LBB4
	.byte	0x18
	.string	"i"
	.byte	0x1
	.byte	0x9c
	.byte	0xf
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0x13
	.4byte	.LBB5
	.4byte	.LBE5-.LBB5
	.byte	0x18
	.string	"sh"
	.byte	0x1
	.byte	0x9d
	.byte	0x18
	.4byte	0x4a4
	.byte	0x2
	.byte	0x91
	.byte	0x4c
	.byte	0x1a
	.4byte	.LASF46
	.byte	0x1
	.byte	0x9e
	.byte	0x12
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x48
	.byte	0
	.byte	0
	.byte	0
	.byte	0x5
	.byte	0x4
	.4byte	0x1b5
	.byte	0x21
	.string	"run"
	.byte	0x1
	.byte	0x8a
	.byte	0x5
	.4byte	0x75
	.4byte	.LFB10
	.4byte	.LFE10-.LFB10
	.byte	0x1
	.byte	0x9c
	.4byte	0x693
	.byte	0x1c
	.4byte	.LASF59
	.byte	0x1
	.byte	0x8a
	.byte	0x1b
	.4byte	0xaf
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x1a
	.4byte	.LASF70
	.byte	0x1
	.byte	0x8c
	.byte	0x8
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x1a
	.4byte	.LASF71
	.byte	0x1
	.byte	0x8d
	.byte	0x9
	.4byte	0x698
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0x22
	.4byte	0x75
	.byte	0x5
	.byte	0x4
	.4byte	0x693
	.byte	0x23
	.4byte	.LASF72
	.byte	0x1
	.byte	0x52
	.byte	0x5
	.4byte	0x75
	.4byte	.LFB9
	.4byte	.LFE9-.LFB9
	.byte	0x1
	.byte	0x9c
	.4byte	0x70b
	.byte	0x18
	.string	"in"
	.byte	0x1
	.byte	0x54
	.byte	0x8
	.4byte	0xa8
	.byte	0x2
	.byte	0x91
	.byte	0x5f
	.byte	0x1a
	.4byte	.LASF73
	.byte	0x1
	.byte	0x58
	.byte	0x7
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x1a
	.4byte	.LASF74
	.byte	0x1
	.byte	0x59
	.byte	0x7
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x60
	.byte	0x1a
	.4byte	.LASF59
	.byte	0x1
	.byte	0x5b
	.byte	0x12
	.4byte	0xaf
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0x13
	.4byte	.LBB3
	.4byte	.LBE3-.LBB3
	.byte	0x18
	.string	"i"
	.byte	0x1
	.byte	0x78
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x64
	.byte	0
	.byte	0
	.byte	0x24
	.4byte	.LASF75
	.byte	0x1
	.byte	0x4a
	.byte	0x6
	.4byte	.LFB8
	.4byte	.LFE8-.LFB8
	.byte	0x1
	.byte	0x9c
	.4byte	0x757
	.byte	0x1d
	.string	"buf"
	.byte	0x1
	.byte	0x4a
	.byte	0x20
	.4byte	0xaf
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x1d
	.string	"len"
	.byte	0x1
	.byte	0x4a
	.byte	0x28
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x13
	.4byte	.LBB2
	.4byte	.LBE2-.LBB2
	.byte	0x18
	.string	"i"
	.byte	0x1
	.byte	0x4b
	.byte	0xb
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0
	.byte	0x25
	.4byte	.LASF76
	.byte	0x1
	.byte	0x36
	.byte	0x6
	.4byte	.LFB7
	.4byte	.LFE7-.LFB7
	.byte	0x1
	.byte	0x9c
	.4byte	0x79a
	.byte	0x18
	.string	"in"
	.byte	0x1
	.byte	0x37
	.byte	0x9
	.4byte	0xa8
	.byte	0x2
	.byte	0x91
	.byte	0x67
	.byte	0x1a
	.4byte	.LASF70
	.byte	0x1
	.byte	0x38
	.byte	0xa
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0x1a
	.4byte	.LASF77
	.byte	0x1
	.byte	0x39
	.byte	0x7
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x1b
	.4byte	.LASF78
	.byte	0x1
	.byte	0x2d
	.byte	0x6
	.4byte	.LFB6
	.4byte	.LFE6-.LFB6
	.byte	0x1
	.byte	0x9c
	.4byte	0x7cf
	.byte	0x1d
	.string	"str"
	.byte	0x1
	.byte	0x2d
	.byte	0x18
	.4byte	0xa2
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x18
	.string	"pos"
	.byte	0x1
	.byte	0x2e
	.byte	0x7
	.4byte	0x75
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x24
	.4byte	.LASF79
	.byte	0x1
	.byte	0x27
	.byte	0x6
	.4byte	.LFB5
	.4byte	.LFE5-.LFB5
	.byte	0x1
	.byte	0x9c
	.4byte	0x7f3
	.byte	0x1d
	.string	"c"
	.byte	0x1
	.byte	0x27
	.byte	0x14
	.4byte	0xa8
	.byte	0x2
	.byte	0x91
	.byte	0x6f
	.byte	0
	.byte	0x26
	.4byte	.LASF81
	.byte	0x1
	.byte	0x23
	.byte	0x6
	.4byte	.LFB4
	.4byte	.LFE4-.LFB4
	.byte	0x1
	.byte	0x9c
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x25
	.byte	0xe
	.byte	0x13
	.byte	0xb
	.byte	0x3
	.byte	0xe
	.byte	0x1b
	.byte	0xe
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x10
	.byte	0x17
	.byte	0
	.byte	0
	.byte	0x2
	.byte	0x24
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x3e
	.byte	0xb
	.byte	0x3
	.byte	0xe
	.byte	0
	.byte	0
	.byte	0x3
	.byte	0x16
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x4
	.byte	0x24
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x3e
	.byte	0xb
	.byte	0x3
	.byte	0x8
	.byte	0
	.byte	0
	.byte	0x5
	.byte	0xf
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x6
	.byte	0x13
	.byte	0x1
	.byte	0xb
	.byte	0xb
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x7
	.byte	0xd
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x38
	.byte	0xb
	.byte	0
	.byte	0
	.byte	0x8
	.byte	0x1
	.byte	0x1
	.byte	0x49
	.byte	0x13
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x9
	.byte	0x21
	.byte	0
	.byte	0x49
	.byte	0x13
	.byte	0x2f
	.byte	0xb
	.byte	0
	.byte	0
	.byte	0xa
	.byte	0x13
	.byte	0x1
	.byte	0xb
	.byte	0xb
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xb
	.byte	0xd
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x38
	.byte	0xb
	.byte	0
	.byte	0
	.byte	0xc
	.byte	0x16
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xd
	.byte	0x13
	.byte	0x1
	.byte	0x3
	.byte	0xe
	.byte	0xb
	.byte	0xb
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xe
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x3f
	.byte	0x19
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0xf
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x3f
	.byte	0x19
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x10
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x3f
	.byte	0x19
	.byte	0x3c
	.byte	0x19
	.byte	0
	.byte	0
	.byte	0x11
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x12
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x13
	.byte	0xb
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0
	.byte	0
	.byte	0x14
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0x5
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x15
	.byte	0x15
	.byte	0x1
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x16
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0
	.byte	0x17
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x18
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x19
	.byte	0xb
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x1a
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x1b
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x27
	.byte	0x19
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x1c
	.byte	0x5
	.byte	0
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x1d
	.byte	0x5
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x1e
	.byte	0x2e
	.byte	0
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0
	.byte	0
	.byte	0x1f
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x27
	.byte	0x19
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x20
	.byte	0x2e
	.byte	0
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x97,0x42
	.byte	0x19
	.byte	0
	.byte	0
	.byte	0x21
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x27
	.byte	0x19
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x22
	.byte	0x15
	.byte	0
	.byte	0x27
	.byte	0x19
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x23
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x24
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x27
	.byte	0x19
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x97,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x25
	.byte	0x2e
	.byte	0x1
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x97,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x26
	.byte	0x2e
	.byte	0
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.byte	0x97,0x42
	.byte	0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.4byte	0x1c
	.2byte	0x2
	.4byte	.Ldebug_info0
	.byte	0x4
	.byte	0
	.2byte	0
	.2byte	0
	.4byte	.Ltext0
	.4byte	.Letext0-.Ltext0
	.4byte	0
	.4byte	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF67:
	.string	"header"
.LASF32:
	.string	"e_shstrndx"
.LASF62:
	.string	"run_file_stub"
.LASF16:
	.string	"Elf32_Word"
.LASF23:
	.string	"e_entry"
.LASF59:
	.string	"load_ram_base"
.LASF58:
	.string	"temp"
.LASF2:
	.string	"short int"
.LASF72:
	.string	"load"
.LASF80:
	.string	"ls_stub"
.LASF26:
	.string	"e_flags"
.LASF76:
	.string	"waitForStart"
.LASF43:
	.string	"sh_entsize"
.LASF44:
	.string	"Elf32_Shdr"
.LASF28:
	.string	"e_phentsize"
.LASF50:
	.string	"uart"
.LASF78:
	.string	"sendstring"
.LASF53:
	.string	"ftype"
.LASF69:
	.string	"string_st"
.LASF5:
	.string	"__uint16_t"
.LASF15:
	.string	"Elf32_Half"
.LASF30:
	.string	"e_shentsize"
.LASF79:
	.string	"sendchar"
.LASF47:
	.string	"length"
.LASF20:
	.string	"e_type"
.LASF27:
	.string	"e_ehsize"
.LASF8:
	.string	"long long int"
.LASF9:
	.string	"long long unsigned int"
.LASF66:
	.string	"getBssHeader"
.LASF18:
	.string	"Elf32_Off"
.LASF75:
	.string	"readBytes"
.LASF35:
	.string	"sh_type"
.LASF56:
	.string	"shell"
.LASF22:
	.string	"e_version"
.LASF6:
	.string	"__uint32_t"
.LASF42:
	.string	"sh_addralign"
.LASF48:
	.string	"FileHeader"
.LASF36:
	.string	"sh_flags"
.LASF60:
	.string	"bssHeader"
.LASF11:
	.string	"long double"
.LASF1:
	.string	"unsigned char"
.LASF71:
	.string	"boot_main"
.LASF0:
	.string	"signed char"
.LASF33:
	.string	"Elf32_Ehdr"
.LASF41:
	.string	"sh_info"
.LASF13:
	.string	"uint32_t"
.LASF10:
	.string	"unsigned int"
.LASF12:
	.string	"uint16_t"
.LASF64:
	.string	"fname"
.LASF83:
	.string	"boot.c"
.LASF38:
	.string	"sh_offset"
.LASF70:
	.string	"start"
.LASF3:
	.string	"short unsigned int"
.LASF39:
	.string	"sh_size"
.LASF14:
	.string	"char"
.LASF4:
	.string	"long int"
.LASF61:
	.string	"main"
.LASF45:
	.string	"type"
.LASF40:
	.string	"sh_link"
.LASF24:
	.string	"e_phoff"
.LASF74:
	.string	"perc_top"
.LASF21:
	.string	"e_machine"
.LASF37:
	.string	"sh_addr"
.LASF25:
	.string	"e_shoff"
.LASF7:
	.string	"long unsigned int"
.LASF34:
	.string	"sh_name"
.LASF54:
	.string	"fileHeader"
.LASF49:
	.string	"led_state"
.LASF29:
	.string	"e_phnum"
.LASF57:
	.string	"upload_loop"
.LASF52:
	.string	"uart_in"
.LASF68:
	.string	"spnt"
.LASF63:
	.string	"cd_stub"
.LASF73:
	.string	"perc_count"
.LASF46:
	.string	"name"
.LASF81:
	.string	"setled"
.LASF31:
	.string	"e_shnum"
.LASF65:
	.string	"readline"
.LASF55:
	.string	"traps"
.LASF19:
	.string	"e_ident"
.LASF51:
	.string	"uart_status"
.LASF17:
	.string	"Elf32_Addr"
.LASF77:
	.string	"st_pos"
.LASF84:
	.string	"/home/markpudd/rvtst/bootloader"
.LASF85:
	.string	"readchar"
.LASF82:
	.string	"GNU C17 10.1.0 -march=rv32i -mabi=ilp32 -mtune=rocket -g -O0"
	.ident	"GCC: (GNU) 10.1.0"
