# AXI4 OSS FVIP public Makefile.
#
# This file is intentionally limited to CI-oriented OSS/SBY entry points.
# Source conversion and extraction scripts are intentionally excluded from the
# public CI workflow.

SHELL := /usr/bin/env bash

SBY ?= sby
PYTHON ?= python3
NICE ?= 0
TIMEOUT ?=
CL1_BRIDGE_DIR ?= example/cl1
CL1_AXI2CACHEBUS_DIR ?= $(CL1_BRIDGE_DIR)
CL1_CROSSBAR_DIR ?= example/cl1_crossbar
CL1_CROSSBAR_AXI2CACHEBUS_DIR ?= $(CL1_CROSSBAR_DIR)

CL1_BRIDGE_DIR_ABS := $(abspath $(CL1_BRIDGE_DIR))
CL1_AXI2CACHEBUS_DIR_ABS := $(abspath $(CL1_AXI2CACHEBUS_DIR))
CL1_CROSSBAR_DIR_ABS := $(abspath $(CL1_CROSSBAR_DIR))
CL1_CROSSBAR_AXI2CACHEBUS_DIR_ABS := $(abspath $(CL1_CROSSBAR_AXI2CACHEBUS_DIR))

RUN_PREFIX :=
ifneq ($(strip $(TIMEOUT)),)
RUN_PREFIX += timeout $(TIMEOUT)
endif
ifneq ($(strip $(NICE)),0)
RUN_PREFIX += nice -n $(NICE)
endif

.DEFAULT_GOAL := help

.PHONY: help ci bmc prove cover \
	cl1-bmc cl1-prove cl1-cover \
	cl1-crossbar-bmc cl1-crossbar-prove cl1-crossbar-cover \
	axi-crossbar-bmc axi-crossbar-cover axi-crossbar-4kb axi-crossbar-reach \
	check-scripts clean

help:
	@echo "AXI4 OSS FVIP"
	@echo ""
	@echo "Common targets:"
	@echo "  make ci                  Run self-contained CL1 BMC checks"
	@echo "  make bmc                 Alias for ci"
	@echo "  make prove               Run CL1 induction checks"
	@echo "  make cover               Run CL1 cover checks"
	@echo "  make clean               Remove SBY run artifacts"
	@echo ""
	@echo "CL1 targets:"
	@echo "  make cl1-bmc             Run example/cl1 BMC"
	@echo "  make cl1-prove           Run example/cl1 prove"
	@echo "  make cl1-cover           Run example/cl1 cover"
	@echo "  make cl1-crossbar-bmc    Run example/cl1_crossbar BMC"
	@echo "  make cl1-crossbar-prove  Run example/cl1_crossbar prove"
	@echo "  make cl1-crossbar-cover  Run example/cl1_crossbar cover"
	@echo ""
	@echo "External AXI crossbar demo targets:"
	@echo "  make axi-crossbar-bmc    Run example/axi_crossbar checker BMC"
	@echo "  make axi-crossbar-cover  Run example/axi_crossbar checker cover"
	@echo "  make axi-crossbar-4kb    Run 4KB boundary demo"
	@echo "  make axi-crossbar-reach  Run reachability cover demo"
	@echo ""
	@echo "Variables:"
	@echo "  SBY=<path>               SymbiYosys command, default: sby"
	@echo "  TIMEOUT=<duration>       Optional timeout wrapper, e.g. 10m"
	@echo "  NICE=<priority>          Optional nice priority, default: 0"
	@echo "  CL1_BRIDGE_DIR=<dir>     CacheBus2Axi4Top RTL dir, default: example/cl1"
	@echo "  CL1_AXI2CACHEBUS_DIR=<dir>"
	@echo "                           Axi4ToCacheBus RTL dir for cl1, default: CL1_BRIDGE_DIR"
	@echo "  CL1_CROSSBAR_DIR=<dir>   CrossbarCacheTop RTL dir, default: example/cl1_crossbar"
	@echo "  CL1_CROSSBAR_AXI2CACHEBUS_DIR=<dir>"
	@echo "                           Axi4ToCacheBus RTL dir for cl1_crossbar, default: CL1_CROSSBAR_DIR"

ci: cl1-bmc cl1-crossbar-bmc

bmc: ci

prove: cl1-prove cl1-crossbar-prove

cover: cl1-cover cl1-crossbar-cover

check-scripts:
	$(PYTHON) -m py_compile ci/*.py

cl1-bmc:
	cd example/cl1 && \
		CL1_BRIDGE_DIR="$(CL1_BRIDGE_DIR_ABS)" \
		CL1_AXI2CACHEBUS_DIR="$(CL1_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh bmc

cl1-prove:
	cd example/cl1 && \
		CL1_BRIDGE_DIR="$(CL1_BRIDGE_DIR_ABS)" \
		CL1_AXI2CACHEBUS_DIR="$(CL1_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh prove

cl1-cover:
	cd example/cl1 && \
		CL1_BRIDGE_DIR="$(CL1_BRIDGE_DIR_ABS)" \
		CL1_AXI2CACHEBUS_DIR="$(CL1_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh cover

cl1-crossbar-bmc:
	cd example/cl1_crossbar && \
		CL1_CROSSBAR_DIR="$(CL1_CROSSBAR_DIR_ABS)" \
		CL1_CROSSBAR_AXI2CACHEBUS_DIR="$(CL1_CROSSBAR_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh bmc

cl1-crossbar-prove:
	cd example/cl1_crossbar && \
		CL1_CROSSBAR_DIR="$(CL1_CROSSBAR_DIR_ABS)" \
		CL1_CROSSBAR_AXI2CACHEBUS_DIR="$(CL1_CROSSBAR_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh prove

cl1-crossbar-cover:
	cd example/cl1_crossbar && \
		CL1_CROSSBAR_DIR="$(CL1_CROSSBAR_DIR_ABS)" \
		CL1_CROSSBAR_AXI2CACHEBUS_DIR="$(CL1_CROSSBAR_AXI2CACHEBUS_DIR_ABS)" \
		SBY="$(SBY)" PYTHON="$(PYTHON)" \
		$(RUN_PREFIX) ./run_prove_with_summary.sh cover

axi-crossbar-bmc:
	cd example/axi_crossbar && $(RUN_PREFIX) $(SBY) -f axi_crossbar_checker.sby prove

axi-crossbar-cover:
	cd example/axi_crossbar && $(RUN_PREFIX) $(SBY) -f axi_crossbar_checker.sby cover

axi-crossbar-4kb:
	cd example/axi_crossbar && $(RUN_PREFIX) $(SBY) -f axi_crossbar_4kb.sby prove

axi-crossbar-reach:
	cd example/axi_crossbar && $(RUN_PREFIX) $(SBY) -f axi_crossbar_reach.sby

clean:
	find example -mindepth 2 -maxdepth 2 -type d \
		\( -name '*_bmc' -o -name '*_prove' -o -name '*_cover' -o -name '*_reach' -o -name '*_4kb' \) \
		-prune -exec rm -rf {} +
	find example -type f \
		\( -name '*.stdout' -o -name 'status' -o -name 'status.path' -o -name 'status.sqlite' \
		   -o -name 'logfile.txt' -o -name 'property_summary.txt' -o -name '*.xml' \
		   -o -name '*.vcd' -o -name '*.fst' -o -name '*.smt2' \
		   -o -name '.*.generated.sby' \) \
		-delete
