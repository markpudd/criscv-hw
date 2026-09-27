# Icarus Verilog builds for the core stage testbenches.
#
#   make            compile + run the fetch, decode, and execute testbenches
#   make fetch      compile + run the fetch testbench
#   make decode     compile + run the decode testbench
#   make execute    compile + run the execute testbench
#   make wave       run fetch and produce fetch.vcd for GTKWave
#   make clean
#


FETCH_RTL   ?= ../fetch.v
FETCH_MODEL  = sim_models/mmu_sim_model.v
FETCH_TB     = fetch_tb.sv
FETCH_OUT    = fetch_tb
DECODE_RTL   = ../decode.v
DECODE_TB    = decode_tb.sv
DECODE_OUT   = decode_tb
EXECUTE_RTL  = ../execute.v
EXECUTE_ALU  = ../alu.v
EXECUTE_TB   = execute_tb.sv
EXECUTE_OUT  = execute_tb
CRISCV_RTL   = ../criscv.v ../fetch.v ../decode.v ../execute.v ../alu.v sim_models/mmu_sim_model.v	sim_models/sim_stubs.v	
CRISCV_TB    = criscv_tb.v
CRISCV_OUT   = criscv_tb
IVFLAGS     = -g2005 -Wall -Wno-timescale

.PHONY: all fetch run strict verbose decode execute pipeline wave clean

all: fetch decode execute pipeline

$(FETCH_OUT): $(FETCH_TB) $(FETCH_RTL) $(FETCH_MODEL)
	iverilog $(IVFLAGS) -o $(FETCH_OUT) $(FETCH_TB) $(FETCH_RTL) $(FETCH_MODEL)

fetch run: $(FETCH_OUT)
	vvp ./$(FETCH_OUT)

strict: $(FETCH_OUT)
	vvp ./$(FETCH_OUT) +strict

verbose: $(FETCH_OUT)
	vvp ./$(FETCH_OUT) +verbose

$(DECODE_OUT): $(DECODE_TB) $(DECODE_RTL)
	iverilog $(IVFLAGS) -o $(DECODE_OUT) $(DECODE_TB) $(DECODE_RTL)

decode: $(DECODE_OUT)
	vvp ./$(DECODE_OUT)

$(EXECUTE_OUT): $(EXECUTE_TB) $(EXECUTE_RTL) $(EXECUTE_ALU)
	iverilog $(IVFLAGS) -o $(EXECUTE_OUT) $(EXECUTE_TB) $(EXECUTE_RTL) $(EXECUTE_ALU)

execute: $(EXECUTE_OUT)
	vvp ./$(EXECUTE_OUT)

$(CRISCV_OUT): $(CRISCV_TB) $(CRISCV_RTL)
	iverilog $(IVFLAGS) -o $(CRISCV_OUT) $(CRISCV_TB) $(CRISCV_RTL)

pipeline: $(CRISCV_OUT)
	vvp ./$(CRISCV_OUT)
	@echo "wrote criscv_tb.vcd - open with: gtkwave criscv_tb.vcd"

wave: $(FETCH_OUT)
	vvp ./$(FETCH_OUT) +vcd
	@echo "wrote fetch.vcd"

clean:
	rm -f $(FETCH_OUT) $(DECODE_OUT) $(EXECUTE_OUT) $(CRISCV_OUT) fetch.vcd decode.vcd execute.vcd criscv_tb.vcd
