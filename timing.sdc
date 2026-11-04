create_clock -period 50MHz  [get_ports CLOCK_50]

create_clock -period 50MHz  [get_ports mclk]

derive_pll_clocks

set_clock_groups -asynchronous \
    -group [get_clocks {*video_clock*}] \
    -group [get_clocks {*mem_clock*} {*dram_clk*}]