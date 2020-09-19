create_clock -period 50MHz  [get_ports CLOCK_50]

create_clock -period 50MHz  [get_ports mclk]

derive_pll_clocks
