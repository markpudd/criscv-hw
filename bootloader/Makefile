
CC=/opt/riscv/bin/riscv32-unknown-elf-gcc
OBJS = stdfn.o boot.o

CFLAGS=-ffreestanding  --specs=nosys.specs --specs=nano.specs  -Wl,-N  -Xlinker --script=bootlink.x -Wall -g

boot: boot.o  $(OBJS)
	 $(CC) -o $@ $^ $(CFLAGS)
	 python bintohex.py boot > boot.hex
clean:
	rm boot boot.hex $(OBJ)
