# Synthesizable RISC-V verilog

This is a simple RISC-V verilog implementation (RV32I).   Its not currently fully tested but has successfully run some simple code.  The fn.hex file is a basic Hello World which sends Hello World out on sout (9600 with 50Mhz clock) and blinks port.

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

Once started reset will need to be set low then high to get things running. To build some code to run the easiest thing to do to test is write some simple RISC-V assembler and compile with the RISC-V toolchain.  The binary can then be converted to a .hex file and pointed too for ram initialisation (covert.py coming to do this for you).

## Performance

Using a 50Mhz clock this will take between 10-20 clock cycle per instruction mainly due to memory access , which could be optimised.   A PLL can be used to increase the internal clock speed and accelerate this.

## Running a binary

You can run a binary built with the RISC-V gcc toolchain (and newlib).   At the moment this is built in when you create the core so is a bit of a convoluted process.

Build with

          - /opt/riscv/bin/riscv32-unknown-elf-gcc -ffreestanding -pedantic -nostartfiles -Wl,-N -Wall test.c

This will build a binary with no start up code (so just the raw code for main and any other function you have).  It will also disable paging so the .sdata section will be located directly after .text section.   You will get a warning saying that there is no entry function.  To get code running in the short term you will need to set the pc on start-up.   Get the address of main by running:-

          - /opt/riscv/riscv32-unknown-elf/bin/readelf -s a.out

And noting down the address of main.  You will need to set the pc in crisc.v were reset is checked (around line 120).

The next step is to convert the elf binary to hex with bintohex.py (this also currently change endianist which will change in a future revision).

          - python bintohex.py a.out > boot.hex

Finally copy the hex file and add to your Quartus project, then in the MegaFunction verilog set the init_file to the hex file you've copied across.

There is no memory overwrite protection or checking of sizes.   You will also potentially have to change the stack address in reset if you have configured a different amount of RAM.

## TODO

Few thing likely to:-

    - Add some pipelineing and rewrite all the memory verilog  
    - Add SDRAM to memory controller
    - Create a proper memory layout
    - Add EBREAK/ECALL and FENCE implementations (currently do nothing)
    - Add some more peripherals
    - Build on a different FPGA (Have a Lattice board so may try that)
    - As only 14% of capacity used may be worth trying to build a dual core version......
