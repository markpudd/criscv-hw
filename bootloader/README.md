# Bootloader

This is a really simple bootloader which basicly listens on a serial port for a .hex file generated from the python script in this repo.  The bootloader will load the hex file to 0x10000 which is the start of SDRAM.   Once this is done it will jump to the entry point.


