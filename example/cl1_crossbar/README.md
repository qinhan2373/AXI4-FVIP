# CL1 Crossbar OSS Example

This example verifies the CL1 two-input CacheBus crossbar composition in the
OSS/SBY flow:

```text
AXI source 0 -> Axi4ToCacheBus -> CrossbarCacheTop input 0
AXI source 1 -> Axi4ToCacheBus -> CrossbarCacheTop input 1
CrossbarCacheTop AXI output -> CL1 slave model
```

All three AXI boundaries use the CL1 profile: single ID, single outstanding,
INCR bursts, up to eight beats, no exclusive/EXOKAY, and tied-off sidebands.

Run setup:

```sh
cd example/cl1_crossbar
sby --setup -f cl1_crossbar_checker.sby bmc
```

Run proof with an assertion summary:

```sh
cd example/cl1_crossbar
timeout 10m nice -n 10 ./run_prove_with_summary.sh prove
```
