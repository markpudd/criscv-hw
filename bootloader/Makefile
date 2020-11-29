
CC=/opt/riscv/bin/riscv32-unknown-elf-gcc
OBJS = stdfn.o boot.o

CFLAGS=-ffreestanding -s --specs=nosys.specs --specs=nano.specs  -Wl,-N  -Xlinker --script=bootlink.x -Wall

boot: boot.o  $(OBJS)
	 $(CC) -o $@ $^ $(CFLAGS)
	 python bintohex.py boot > boot.hex
clean:
	rm boot boot.hex $(OBJ)
