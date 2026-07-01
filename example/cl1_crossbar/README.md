# CL1 Crossbar OSS Example

This example verifies the CL1 two-input CacheBus crossbar composition in two
independent flows:

- `protocol/`: AXI protocol checking on both upstream AXI inputs and the
  downstream AXI output.
- `data_integrity/`: crossbar write/read data-consistency checking with
  proof-helper targets for the heavier write and read paths.

The checked composition is:

```text
AXI source 0 -> Axi4ToCacheBus -> CrossbarCacheTop input 0
AXI source 1 -> Axi4ToCacheBus -> CrossbarCacheTop input 1
CrossbarCacheTop AXI output -> CL1 slave model
```

All three AXI boundaries use the CL1 profile: single ID, single outstanding,
INCR bursts, up to eight beats, no exclusive/EXOKAY, and tied-off sidebands.

## Protocol Check

```sh
make cl1-crossbar-bmc
make cl1-crossbar-prove
make cl1-crossbar-cover
```

The protocol scripts write the SBY run under `example/cl1_crossbar/protocol/`
and append a `SBY PROPERTY SUMMARY` section to the generated `logfile.txt`.

## Data-Integrity Check

```sh
make cl1-crossbar-di-bmc
```

The data-integrity flow supports these runsets:

- `DI_RUNSET=upstream-bp`
- `DI_RUNSET=downstream-aww`
- `DI_RUNSET=downstream-aww-main`
- `DI_RUNSET=downstream-ar`
- `DI_RUNSET=downstream-ar-main`
- `DI_RUNSET=proof-helpers`
- `DI_RUNSET=signoff`

Example:

```sh
DI_RUNSET=upstream-bp DI_DEPTH=64 make cl1-crossbar-di-bmc
```

Each data-integrity run writes a Markdown summary under a stable directory such
as `example/cl1_crossbar/data_integrity/work/cl1_crossbar_data_integrity_signoff_bmc/`. The
same runset and mode overwrite the previous output by default. The summary
records every sub-target separately, including helper targets, runtime, and
selected assertion count. The Makefile applies `DI_TIMEOUT=60m` to
data-integrity runs unless overridden.

## External RTL

By default, the Makefile uses the RTL files committed in this directory. CI can
point to generated RTL without editing the SBY files:

```sh
make cl1-crossbar-bmc CL1_CROSSBAR_DIR=/path/to/crossbar
make cl1-crossbar-di-bmc CL1_CROSSBAR_DIR=/path/to/crossbar
```

`CL1_CROSSBAR_DIR` must contain `CrossbarCacheTop.sv`. The AXI source adapter
`axi4toCacheBus.sv` is looked up in the same directory by default, or supplied
separately with `CL1_CROSSBAR_AXI2CACHEBUS_DIR`.
