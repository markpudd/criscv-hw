# mmu.v testbench (Icarus Verilog)

Simulation-only harness for `mmu.v`. Nothing here goes into the Quartus project.

```
tb_mmu.v                 self-checking testbench
sim_models/ram.v         behavioural stand-in for the altsyncram `ram` instance
sim_models/memcache.v    behavioural stand-in for the L1 cache / SDRAM front end
Makefile
```

```
make RTL=path/to/mmu.v          # functional suite
make RTL=path/to/mmu.v strict   # strict AXI VALID/READY master
make RTL=path/to/mmu.v wave     # + mmu_tb.vcd
make real_sdram                 # real mmu/cache/SDRAM integration suite
make real_sdram_wave            # integration suite + mmu_sdram_tb.vcd
```

## Real SDRAM integration bench

`tb_mmu_sdram.v` connects the real `mmu.v`, `memcahce.v`, and `sdramburst.v`
to `IS42VM16400K.v`. The cache and tag RAMs are represented by the
simulation-only models in `sim_models/cache.v` and `sim_models/cachelookup.v`;
the Quartus `altera_mf` libraries are not required.

The ISSI model initializes four 1M-word banks, so startup takes about 5,000
memory-clock cycles. The suite checks an SDRAM-backed cache-line fill, a cache
hit, and an odd-address three-beat word access. With the current RTL, the last
check is expected to fail as `0xXXabcdef`: `mmu.v` captures the final byte of
`WORD_ODD_P3` from the low byte lane even though that address is odd. The
model also reports SDRAM timing violations from the existing controller; those
are emitted by `IS42VM16400K.v` and are not suppressed by the bench.

## Contract the testbench assumes

The current `mmu.v` is not AXI4-Lite yet, so the default master follows what the
RTL actually implements:

- `address`, `size`, `rw`, `write_data` are held stable for the whole
  transaction. The master may not change them mid-op.
- `s_ready` is a **single-cycle completion strobe** (`cState == DONE`), not an
  AXI READY. `read_data` is only valid during that one cycle.
- The master drops `s_valid` *inside* the `s_ready` cycle. Under real AXI the
  master would hold VALID across the rising edge on which it samples READY —
  that is what `+strict` does, and it changes the results (see below).
- `m_ready` is not connected to anything inside the DUT.

Deviations from AXI4-Lite are reported as `PROTO` / `WARN` lines rather than
failures, so the functional suite always runs to completion.

## Model assumptions worth checking against your real RTL

`sim_models/memcache.v` models: `rw_req` held high, `data_valid` pulsed for one
clock `LATENCY` clocks later with `read_data` valid on that same clock, then the
beat counter re-arms so a held `rw_req` produces a beat every `LATENCY+1` clocks.
That is what `mmu.v` needs to walk its multi-beat unaligned accesses. If the real
`memcache` returns data one clock *after* `data_valid`, the MMU capture logic is
off by a cycle and this stub will hide it — worth confirming.

`ce` deliberately does **not** gate the request inside the stub, because
`mem_req` in `mmu.v` has no `ce` term. The stub counts those accesses instead of
hiding them.

`sim_models/ram.v` models a single-port M9K with a registered output (1 clock
latency), byte enables, read-during-write = new data.

## Coverage

Sections A and B run the same 21-check suite against the local block RAM
(`ce=0`) and the memcache region (`ce=1`): word/half/byte at even and odd
addresses, all three beat counts, word-in/bytes-out and bytes-in/word-out
endianness cross-checks, byte-enable neighbour corruption, and zero-extension of
sub-word reads. C checks the physical byte layout in the RAM array. D–J cover
back-to-back transactions, `m_ready` backpressure, `read_data` lifetime, address
aliasing, spurious `memcache` requests, `address[31]=1`, and reset mid-transaction.
