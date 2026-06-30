# CL1 OSS Example

This is the OSS-compatible CL1 bridge composition check. It uses the converted
AXI4 checker under the CL1 profile: single outstanding, ID zero, INCR bursts,
up to eight beats, no exclusive/EXOKAY, and tied-off optional sidebands.

The SBY script applies `../../formal/cl1_profile_filter.ys` after `prep` to
remove CL1-out-of-scope assert/assume/cover targets. Reuse that file from new
CL1-like projects instead of copying local waiver lists.

Setup-only sanity:

```sh
cd example/cl1
sby --setup -f cachebus2axi4_checker.sby bmc
```

Full proof with a post-run assertion list:

```sh
cd example/cl1
timeout 5m nice -n 10 ./run_prove_with_summary.sh prove
```

The wrapper appends a `SBY PROPERTY SUMMARY` section to
`cachebus2axi4_checker_prove/logfile.txt` and writes the same content to
`cachebus2axi4_checker_prove/property_summary.txt`. In a passing `prove` task,
every listed `ASSERT` entry is proven; skipped `COVER` entries are only listed
for accounting and require the separate `cover` task for reachability.
