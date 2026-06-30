# CL1 Unreachable Invariants

`cl1_oss_unreachable_invariants.sv` contains reusable helper assertions for
OSS/SBY CL1 proofs.

These assertions are not AXI protocol rules and are not DUT constraints. They
prove that the CL1 formal traffic driver, the lightweight write-dependency
scoreboard, and the simple downstream slave model cannot enter states that are
unreachable by construction. This gives k-induction a compact set of state
facts to reuse across CL1-like examples.

Use the modules from an example testbench:

- `cl1_oss_source_driver_unreachable_invariants` for each CL1 AXI source
  driver feeding an `Axi4ToCacheBus` instance.
- `cl1_oss_cachebus_len_unreachable_invariants` for CL1 CacheBus pipelines
  where request length is known to stay below eight beats.
- `cl1_oss_crossbar_write_pipeline_unreachable_invariants` for crossbar proofs
  that need an assertion-only observer tying the selected source write beat
  count to the downstream slave write beat count across the CacheBus pipeline.
- `cl1_oss_crossbar_read_pipeline_unreachable_invariants` for crossbar proofs
  that need an assertion-only observer tying downstream non-last R beats,
  cachebus response beats, and source-side R beats into one read response
  count.
- `cl1_oss_slave_model_unreachable_invariants` for the shared downstream AXI
  slave model used to respond to a CL1 bridge output.

The crossbar helper also includes CL1 single-outstanding read request facts:
after the downstream slave has accepted an AR, the cachebus arbiter, buscut,
and CacheBus2Axi4 bridge must not retain another pending read request. This
is a proof-only assertion of the CL1 test profile; it is not an AXI rule.

Add the file to the SBY script before the testbench:

```text
read -formal -sv cl1_oss_unreachable_invariants.sv
```

and add it to `[files]`:

```text
../../formal/cl1_oss_unreachable_invariants.sv
```

Keep these helpers as assertions. Turning them into assumptions would constrain
the proof environment and could hide real DUT behavior.

## cl1_crossbar status

Last checked from `AXI4-OSS/example/cl1_crossbar`:

```text
timeout 2m nice -n 10 ./run_prove_with_summary.sh bmc
timeout 10m nice -n 10 ./run_prove_with_summary.sh prove
```

Results:

- BMC: PASS, 316 assertions proven, 15 seconds.
- Prove: PASS by k-induction, 316 assertions proven, 105 seconds.

The final induction blockers were unreachable read-response states:

- A visible non-last cachebus/source response must correspond to one pending
  non-last beat between the downstream slave count and the source count.
- Once the downstream slave has accepted the single CL1 read request, no
  cachebus read request may remain pending in the arbiter, buscut, or
  CacheBus2Axi4 bridge.
