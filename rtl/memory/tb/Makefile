# Icarus Verilog build for the mmu.v testbench.
#
#   make            compile + run the functional suite
#   make strict     run with a strict AXI VALID/READY master
#   make verbose    print every passing check as well
#   make wave       run and produce mmu_tb.vcd for GTKWave
#   make clean
#
# Point RTL at your working copy of mmu.v:
#   make RTL=../rtl/mmu.v

RTL        ?= ../mmu.v
SIM_MODELS  = sim_models/ram.v sim_models/memcache.v
TB          = mmu_tb.v
OUT         = mmu_tb
IVFLAGS     = -g2005 -Wall -Wno-timescale

.PHONY: all run strict verbose wave real_sdram real_sdram_wave clean

all: run

$(OUT): $(TB) $(RTL) $(SIM_MODELS)
	iverilog $(IVFLAGS) -o $(OUT) $(TB) $(RTL) $(SIM_MODELS)

run: $(OUT)
	vvp ./$(OUT)

strict: $(OUT)
	vvp ./$(OUT) +strict

verbose: $(OUT)
	vvp ./$(OUT) +verbose

wave: $(OUT)
	vvp ./$(OUT) +vcd
	@echo "wrote mmu_tb.vcd"

REAL_TB       = tb_mmu_sdram.v
REAL_OUT      = mmu_sdram_tb
REAL_RTL      = ../mmu.v ../memcahce.v ../sdramburst.v
REAL_MODELS   = sim_models/ram.v sim_models/cache.v sim_models/cachelookup.v
REAL_DRAM     = IS42VM16400K.v

$(REAL_OUT): $(REAL_TB) $(REAL_RTL) $(REAL_MODELS) $(REAL_DRAM)
	iverilog $(IVFLAGS) -s tb_mmu_sdram -o $(REAL_OUT) $(REAL_TB) $(REAL_RTL) $(REAL_MODELS) $(REAL_DRAM)

real_sdram: $(REAL_OUT)
	vvp ./$(REAL_OUT)

real_sdram_wave: $(REAL_OUT)
	vvp ./$(REAL_OUT) +vcd
	@echo "wrote mmu_sdram_tb.vcd"

clean:
	rm -f $(OUT) $(REAL_OUT) mmu_tb.vcd mmu_sdram_tb.vcd
