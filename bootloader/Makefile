
CC=/opt/riscv/bin/riscv64-unknown-elf-gcc
OBJS = startup.o stdfn.o boot.o

CFLAGS=-march=rv32i -mabi=ilp32 -ffreestanding -s --specs=nosys.specs --specs=nano.specs  -Wl,-N  -Xlinker --script=bootlink.x -Wall

boot: boot.o  $(OBJS)
	 $(CC) -o $@ $^ $(CFLAGS)
	 /opt/riscv/bin/riscv64-unknown-elf-objcopy -O binary boot boot.bin
	 python3 bintohex.py boot > boot.hex

startup.o: startup.s
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm boot boot.hex $(OBJ)
