# Synthesizable RISC-V verilog

This is a simple RISC-V verilog implementation (RV32I).   Its not currently fully tested but has successfully run some simple code (there is a pin toggle in boot.hex).

## How to get it running
  
This is a simple 3 state FSM (Fetch, decode, execute), with an extra statefor memory commands (load and store), not everything has been tested so there is likely issues with some commands.

This has been tested on a DE0-Nano board (Cyclone IV).  The memory controller (memory-con.v) can use a generated MegaWizard IP set up as:-

          - 1-port RAM
          - 16-bit width (512 size but you can add more)
          - Q enabled

(Lkely redo the memeory controller as it was done in a rush to get things working)

Steps to get it running using Quartus:-

  -  Create new project and import verilog files
  -  Create RAM: 1-Port with 16-bit with and whatever amount of memory you want (as above)
  -  Import RAM initialization file (boot.hex)
  -  Setup CLK input, RESET input (on a button) and an output (which is mapped to 0xffffff00)
  -  Build and program onto an FPGA.  On the DE0-Nano it uses 3192 logic elelments (about 14% capacity)
  
Once started reset will need to be set low then high to get things running. To build some code to run the easiest thing to do to test is write some simple RISC-V assembler and compile with the RISC-V toolchain.  The binary can then be converted to a .hex file and pointed too for ram initialisation (covert.py coming to do this for you).

## Performance

Using a 50Mhz clock this will take between 10-20 clock cycle per instruction mainly due to memory access , which could be optimised.   Its liklely a PLL could be used to increase the internal clock speed and accelerate this substaniatly.

## TODO

Few thing likely to:-

    - Add some pipelineing and rewrite all the memory verilog  
    - Create a proper memory layout
    - Add EBREAK/ECALL and FENCE implementations (currently do nothing)
    - Add some peripherals
    - Build on a different FPGA (Have a Lattice board so may try that)
    - As only 14% of capacity used may be worth trying to build a dual core version......
    
    

