# CL1 Bridge OSS Example

This example verifies the CL1 `CacheBus2Axi4Top` bridge in two independent
flows:

- `protocol/`: AXI protocol checking.
- `data_integrity/`: AXI write/read data-consistency checking.

The protocol flow uses the CL1 AXI profile: single outstanding, ID zero, INCR
bursts, up to eight beats, no exclusive/EXOKAY, and tied-off optional
sidebands. It applies `formal/cl1_profile_filter.ys` after `prep` to remove
CL1-out-of-scope protocol targets.

## Protocol Check

```sh
make cl1-bmc
make cl1-prove
make cl1-cover
```

The protocol scripts write the SBY run under `example/cl1/protocol/` and append
a `SBY PROPERTY SUMMARY` section to the generated `logfile.txt`.

## Data-Integrity Check

```sh
make cl1-di-bmc
```

The data-integrity flow supports these runsets:

- `DI_RUNSET=upstream-bp`
- `DI_RUNSET=downstream-aww`
- `DI_RUNSET=downstream-ar`
- `DI_RUNSET=downstream-ar-main`
- `DI_RUNSET=downstream-ar-helpers`
- `DI_RUNSET=signoff`

Example:

```sh
DI_RUNSET=downstream-aww DI_DEPTH=64 make cl1-di-bmc
```

Each data-integrity run writes a Markdown summary under a stable directory such
as `example/cl1/data_integrity/work/cl1_bridge_data_integrity_signoff_bmc/`. The
same runset and mode overwrite the previous output by default. The Makefile
applies `DI_TIMEOUT=60m` to data-integrity runs unless overridden.

## External RTL

By default, the Makefile uses the RTL files committed in this directory. CI can
point to generated RTL without editing the SBY files:

```sh
make cl1-bmc CL1_BRIDGE_DIR=/path/to/cachebus2axi4
make cl1-di-bmc CL1_BRIDGE_DIR=/path/to/cachebus2axi4
```

`CL1_BRIDGE_DIR` must contain `CacheBus2Axi4Top.sv`. The AXI source adapter
`axi4toCacheBus.sv` is looked up in the same directory by default, or supplied
separately with `CL1_AXI2CACHEBUS_DIR`.
