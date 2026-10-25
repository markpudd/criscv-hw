# Synthesizable RISC-V verilog

## Update

Finally update after a long break.  More to come but headlines are:-

   - Move to a 3 stage pipeline from the original FSM.   Some of the stages have a few extra clock cycles but these should be reduced soon.
   - L1 Instruction cache has been temporarily removed
   - Requires alignement of memory
   - Trap handling fixed (only available for ECALL)
   - SPI peripheral added
   - More robust UART
   - Updated bootloader now with SD card
   - Big reduction in LE's, core is ~4000.
   - Increase number of testbenches
   - Improved memory reads so sum instructions are executed in 2 cycles which likely drop to 1 with the next update.





## Info   

This is a simple RISC-V verilog implementation (RV32I).   Its not currently fully tested but has successfully run some simple code.  There is a bootloader hex file in the booloader diectory which will allow the uploading of a hex file to SDRAM and execute it.

If your looking to build and run DOOM, basic instructions are here https://github.com/markpudd/criscv-hw/wiki/Running-DOOM

## Current Specs

* 50Mhz clock
* 128 Instruction read only L1 cache
* 128K 2 Way associative L2 cache
* SDRAM controller
* UART
* SPI
* Video Output- 256 color palatte (4bit per chanel) 320x200 scaled VGA output
* Basic bootloader with basic System functions implemented (via ECALL) now with support to load for SD card via SPI
* ~4000 Logic elements when synthised on Cyclone IV E (22,230 avalible LEs)
* Tested on DE0-Nano

These specs are based on running on Cyclone IV but this could be reconfigure for other FPGA's.

## MMU
 
The MMU cache is a 2 way associative cache (64 bytes per entry) 
    
By default the SDRAM as any address over 0x10000 (otherwise onboard).  The MMU is used for SDRAM caching, it is a direct mapped cahce (2-way associative is coming).  There is still a bunch of optimazation coming for the cahce which should drop the cache hit access time to 1-2 cycles.

The SDRAM burst is design to be used from multiple source (cache, video and DMA).

## UART

There a basic UART which can be used to upload code.  There is a 16 byte buffer on UART RX.

## Video

*This currently has some display artifacting which will be fixed*

There is some 4 bit VGA support.  It uses 640x480, although the image  stored in memory will be 320x240 with a 256 byte palette.  The palette is written to at 0xfff7fc00.  There is commands at 0xfff7ff00 to set the frame start in SDRAM.

The video code uses a lot of resources mainly due to the paltte and scanline buffers.  It should be reasonbly easy to modify for higher res


## Bootloader

There is a basic binary bootloader.  To use, this build a binary as below use outtobin.py to add the length to the begining of the file.   

The boot.c uses the SPI peripheral at 4Mz to try and load a boot file which can be built from the bootbin directory with and the written to SD card with   dd if=/Volumes/fpga/bootbin/build/boot.elf  of={disk id where card is} bs=512 seek=1 conv=sync.  The bootbin build will give basic read access via FatFS.  If you cross compile some code you should be able to copy to SD card an run.

There is basic ECALL support.  The bootloader has some basic system call implementations so code can execute some system functions.

## How to get it running

I intend to create some videos on how to get this up and running and better docs, but at a high level for Cyclones you need to do the following.  I'm in the process of updating the Verilog to System verilog with added suppport for Xilinix.

This has been tested on a DE0-Nano board (Cyclone IV).  The memory controller (memory_con.v) can use a generated MegaWizard IP set up as:-

          - 1-port RAM
          - 16-bit width (4096 size but you can add more, stack may need changed)
          - Q enabled
          - Module name ram

Steps to get it running using Quartus:-

  -  Create new project and import verilog files
  -  Create RAM: 1-Port with 16-bit with and whatever amount of memory you want (as above)
  -  Import RAM initialisation file (boot.hex)
  -  Setup CLK input, RESET input (on a button) and an output (which is mapped to 0xffffff00)
  -  Build and program onto an FPGA.  On the DE0-Nano it uses 9154 elements with UART and MMU.
  -  Hook up SDRAM and serial
  -  Optionally connect port/crash/status leds.

Once started reset will need to be set low then high to get things running. To build some code to run the easiest thing to do to test is write some simple RISC-V assembler and compile with the RISC-V toolchain.  The binary can then be converted to a .hex file and the uploaded via the bootloader.  An example build command for c is:-

   - /opt/riscv/bin/riscv32-unknown-elf-gcc  -ffreestanding  --specs=nano.specs -Wl,-N  -g print.c


## Performance /  Memory

There has been a number of memory optimisations leadig to less stalls and some instrution require only 2 cycles.  This will likely drop to 1 cycle in the near future, which is why the old L1 distruted RAM was removed.  I will probably add the option of dualport ram for the caches to minimize the memory stalls.

The inition boot.hex is loaded in low ram (under 0x10000) and anything above this uses SDRAM.


## TODO

Few thing likely to:-

    ~~- Add some pipelineing and rewrite all the memory verilog~~  
    - Create a proper memory layout
    - Add EBREAK/ECALL and FENCE implementations (short term link stdfn.c and build code with --specs=nano.specs)
    - Add some more peripherals
    - Build on a different FPGA - Xilinx will be next
    - Dual core
    - Buffering and SW config in UART
