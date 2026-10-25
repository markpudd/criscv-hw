# MMU testbench (Icarus Verilog)

The default test exercises the dual-request arbiter in `mmu.v`:

- simultaneous instruction and data requests select the data request first;
- the instruction request is serviced immediately after the data request
  completes, without an idle cycle on the MMU's memory-side valid;
- each completion is returned only to the request owner.

Run it with:

```sh
make
```

To use a different MMU source file:

```sh
make RTL=path/to/mmu.v
```

The testbench uses the behavioral `ram` and `memcache` models in `sim_models/`.
The older single-request functional benches remain in this directory, but are
not the default target because they use the previous MMU interface.
