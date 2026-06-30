# CL1 Profile Filter

`cl1_profile_filter.ys` is the shared Yosys/SBY filter for CL1-like OSS AXI4
projects.

Use it after `prep`:

```yosys
prep -top <top>
script cl1_profile_filter.ys
```

Add the file to the SBY `[files]` list with the right relative path, for
example:

```text
../../formal/cl1_profile_filter.ys
```

The filter removes assert/assume/cover cells for CL1-out-of-scope AXI4
features: multi-ID behavior, FIXED/WRAP/exclusive/EXOKAY/LP behavior, dynamic
LOCK behavior, bounded READY_MAXWAIT recommendations, and dynamic
USER/CACHE/PROT/QOS/REGION sideband behavior. Core CL1 rules remain active:
reset exit, valid-ready stability, INCR burst length/size, 4KB boundary, WSTRB
legality, write response dependency, read response dependency, WLAST, and
RLAST/count matching.

This is a profile filter, not a protocol relaxation. It should be inherited by
projects whose RTL has the same CL1 limitations. A project supporting a wider
AXI4 subset should use a different profile or remove the corresponding filter
lines.
