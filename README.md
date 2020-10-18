# Synthesizable RISC-V verilog

This is a simple RISC-V verilog implementation (RV32I).   Its not currently fully tested but has successfully run some simple code.  There is a bootloader hex file in the booloader diectory which will allow the uploading of a hex file to SDRAM and execute it.

## MMU

There is some basic code for sdram and caching.   The following is what is available:-

    - memory_cont.v - Basic memory access for on board RAM
    - sdram.v - Basic SDRAM access
    - mmu.v - Basic cached memory using onboard RAM and SDRAM 
    
By default the SDRAM as any address over 0x10000 (otherwise onboard).  The MMU is used for SDRAM caching, it is a direct mapped cahce (2-way associative is coming).  There is still a bunch of optimazation coming for the cahce which should drop the cache hit access time to 1-2 cycles.

## UART

There a basic UART which can be used to upload code.  

## Bootloader

There is a basic binary bootloader (booloader2.c).  To use, this build a binary as below use outtobin.py to add the length to the begining of the file.   You can the send this over serial at 57600.   The code will be loaded at 10000 and use SDRAM (with cach infront).

There is basic ECALL supprot now so it would be possible wto implement things like write as part of the bootloader code which would allow linking with sys for various standard functions.

## How to get it running

This is a simple 3 state FSM (Fetch, decode, execute), with an extra state for memory commands (load and store), not everything has been tested so there is likely issues with some commands.

This has been tested on a DE0-Nano board (Cyclone IV).  The memory controller (memory_con.v) can use a generated MegaWizard IP set up as:-

          - 1-port RAM
          - 16-bit width (4096 size but you can add more, stack may need changed)
          - Q enabled
          - Module name ram

(Likely redo the memory controller as it was done in a rush to get things working)

Steps to get it running using Quartus:-

  -  Create new project and import verilog files
  -  Create RAM: 1-Port with 16-bit with and whatever amount of memory you want (as above)
  -  Import RAM initialisation file (boot.hex)
  -  Setup CLK input, RESET input (on a button) and an output (which is mapped to 0xffffff00)
  -  Build and program onto an FPGA.  On the DE0-Nano it uses 3192 logic elements (about 14% capacity)
  -  Hook up SDRAM and serial
  -  Optionally connect port/crash/status leds.

Once started reset will need to be set low then high to get things running. To build some code to run the easiest thing to do to test is write some simple RISC-V assembler and compile with the RISC-V toolchain.  The binary can then be converted to a .hex file and the uploaded via the bootloader.  An example build command for c is:-

   - /opt/riscv/bin/riscv32-unknown-elf-gcc  -ffreestanding  --specs=nano.specs -Wl,-N  -g stdfn.c print.c

In the bootloader directory there is a basic IO file so you can get things like printf running.

## Performance /  Memory

The memory performance is still not optimize.  Using the MMU SDRAM will be cached, but there is a still a bit of work to do to reduce cachce access clock cycles.

The memory_cont.v is still used to access memory under 0x10000, however this will likely change so that all access will go through MMU.   Stack is currently always located a 0x1ffc.


## TODO

Few thing likely to:-

    - Add some pipelineing and rewrite all the memory verilog  
    - Create a proper memory layout
    - Add EBREAK/ECALL and FENCE implementations (short term link stdfn.c and build code with --specs=nano.specs)
    - Add some more peripherals
    - Build on a different FPGA (Have a Lattice board so may try that)
    - Dual core
    - Buffering and SW config in UART
