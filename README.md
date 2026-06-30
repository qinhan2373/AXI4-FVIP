# AXI4 OSS FVIP

This repository contains the OSS-compatible AXI4 formal verification IP used by
the SymbiYosys/Yosys flow. It is derived from YosysHQ SVA-AXI4-FVIP and keeps
the original ISC license notice in `COPYING`.

## Active Source Layout

`vsrc` is the active OSS checker source tree used by the examples.

The active checker files are:

- `vsrc/amba_axi4_write_address_channel.oss.sv`
- `vsrc/amba_axi4_write_data_channel.oss.sv`
- `vsrc/amba_axi4_write_response_channel.oss.sv`
- `vsrc/amba_axi4_read_address_channel.oss.sv`
- `vsrc/amba_axi4_read_data_channel.oss.sv`
- `vsrc/axi4_lib/amba_axi4_write_response_dependencies.oss.sv`
- `vsrc/axi4_lib/amba_axi4_read_response_dependencies.oss.sv`

The early hand-written
`vsrc/axi4_lib/amba_axi4_write_response_dependencies_oss.sv` subset has been
removed from the active filelists. The wrapper now uses the converted generic
`amba_axi4_write_response_dependencies` module, or the CL1-specialized
`amba_axi4_write_response_dependencies_cl1_oss` module when
`OSS_CL1_LIGHTWEIGHT_WRITE_DEPENDENCIES` is defined.

The converted generic write-response dependency file also includes an
OSS-readable `forward_progress_scoreboard` helper. This keeps the generic
multi-outstanding generate branch elaboratable while the CL1 profile can still
select the lighter single-outstanding implementation for proof capacity.

`vsrc/amba_axi4_monitor_wrapper_oss.sv` is the reusable OSS monitor wrapper for
SBY/riscv-formal style integrations. It exposes a flat AXI signal list and
instantiates `amba_axi4_protocol_checker_oss` in monitor mode without exposing
the checker's proof-only helper outputs to the integration top.

`templates/riscv_formal_axi_monitor` provides a reusable monitor integration
template for adding the OSS AXI protocol checker to riscv-formal/SBY projects.

## CI Entry Points

The top-level `Makefile` is limited to public OSS/SBY checks.

```sh
make ci
make prove
make cover
make clean
```

`make ci` runs the self-contained CL1 BMC checks:

- `example/cl1`
- `example/cl1_crossbar`

By default, the CL1 checks use the RTL committed under the example
directories. CI can point the checks at generated CL1 RTL without editing the
SBY files:

```sh
make cl1-bmc CL1_BRIDGE_DIR=/path/to/cachebus2axi4
make cl1-crossbar-bmc CL1_CROSSBAR_DIR=/path/to/crossbar
```

`CL1_BRIDGE_DIR` must contain `CacheBus2Axi4Top.sv`.
`CL1_CROSSBAR_DIR` must contain `CrossbarCacheTop.sv`.

Both examples also need `axi4toCacheBus.sv` for the AXI source adapter. It is
looked up in the same directory by default, or it can be supplied separately:

```sh
make cl1-bmc \
  CL1_BRIDGE_DIR=/path/to/cachebus2axi4 \
  CL1_AXI2CACHEBUS_DIR=/path/to/axi2cachebus

make cl1-crossbar-bmc \
  CL1_CROSSBAR_DIR=/path/to/crossbar \
  CL1_CROSSBAR_AXI2CACHEBUS_DIR=/path/to/axi2cachebus
```

The `example/axi_crossbar` targets are kept as optional demos because they
depend on the external AXI crossbar RTL listed in their `.sby` files.

Conversion and extraction scripts are maintainer-only regeneration tools. They
are not part of the public CI workflow and are ignored when kept in a local
checkout under `scripts/`. A local `Makefile.convert` may also be kept for that
workflow without being committed.

## Examples

The public example set is intentionally small:

- `example/axi_crossbar`
- `example/cl1`
- `example/cl1_crossbar`

Generated SBY run directories, traces, solver logs, and mutation experiments are
ignored and should not be committed.

## Reset Initial-State Guard

The OSS wrapper `vsrc/amba_axi4_protocol_checker_oss.sv` includes
`FORMAL_INIT_GUARD`, which defaults to `OPTIONAL_RESET`.

When enabled, the wrapper feeds idle/zero AXI values into the converted channel
checkers until one `ACLK` edge has been sampled. This prevents synchronous-reset
DUTs from failing on formal state 0, where resettable registers have not yet
observed a reset clock edge and can still contain arbitrary initial values.

This guard is not a relaxation of AXI reset requirements. After the first
sample, the checkers see the real DUT AXI signals, including while reset is
still asserted and on the first cycle after reset release.

Set `FORMAL_INIT_GUARD` to `1'b0` only when the formal environment already
constrains DUT initial state to a reset-clean state.

## CL1 Profile Filter

CL1-like OSS examples should inherit `formal/cl1_profile_filter.ys` after
`prep -top ...`. The filter removes assert/assume/cover targets for AXI4 modes
that CL1 does not implement, while leaving the CL1-supported protocol rules
active.
