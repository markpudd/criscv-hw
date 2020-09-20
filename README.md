# Synthesizable RISC-V verilog

This is a simple RISC-V verilog implementation (RV32I).   Its not currently fully tested but has successfully run some simple code.  There is a bootloader hex file in the booloader diectory which will allow the uploading of a hex file to SDRAM and execute it.

## SDRAM and UART

There basic support for SDRAM and UART.  Both are pretty simple and buggy (especially the SDRAM) at the moment.  Its likely the SDRAM will get converted into page read/right and a cache which will be simpler and more performant.


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

   - /opt/riscv/bin/riscv32-unknown-elf-gcc  -ffreestanding  --specs=nosys.specs --specs=nano.specs -Wl,-N  -g print.c

In the bootloader directory there is a basic IO file so you can get things like printf running.

## Performance

The memory performance is currently pretty bad, especially for SDRAM.   The current model burst 1 16-bit word from SDRAM and closes the row at a time.  This results in arroud 20 clock cycles for an instruction read (so 4~400ns per instruction).  Its high on the list top switch to paged RAM with caching which should result in a major speed increase.   

If SDRAM is not needed then its possible to use a linker script to locate code in normal RAM which will allow the whole system to be internaly clocked at 400+Mhz using a PLL.




## TODO

Few thing likely to:-

    - Add some pipelineing and rewrite all the memory verilog  
    - Add SDRAM to memory controller
    - Create a proper memory layout
    - Add EBREAK/ECALL and FENCE implementations (currently do nothing)
    - Add some more peripherals
    - Build on a different FPGA (Have a Lattice board so may try that)
    - As only 14% of capacity used may be worth trying to build a dual core version......
