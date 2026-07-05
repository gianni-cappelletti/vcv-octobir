# OctobIR - VCV Rack Library packaging repository.
#
# Source of truth is the October Production Co. monorepo, pinned here as the
# `opc` submodule. This repository exists only so the VCV Library build farm
# sees a standard Rack plugin (plugin.json + Makefile) at the repository root,
# which the rack-plugin-toolchain requires. No source is duplicated: a release
# is a bump of the `opc` submodule pointer plus a version bump in plugin.json.

RACK_DIR ?= ../Rack

OPC := opc
VCV := $(OPC)/plugins/octobir/vcv-rack

FLAGS += -I$(OPC)/libs/octobir-core/include
FLAGS += -I$(OPC)/third_party/WDL/WDL
FLAGS += -I$(OPC)/third_party

# WDL static-asserts that `char` is signed. On ARM (mac-arm64, a Library build
# target) `char` is unsigned by default, tripping the assertion. Force signed
# `char` so all architectures agree; a no-op on x86 where signed is the default.
FLAGS += -fsigned-char

SOURCES += $(wildcard $(VCV)/src/*.cpp)
SOURCES += $(OPC)/libs/octobir-core/src/IRLoader.cpp
SOURCES += $(OPC)/libs/octobir-core/src/IRProcessor.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/convoengine.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/resample.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/fft.c

DISTRIBUTABLES += res
DISTRIBUTABLES += $(wildcard LICENSE*)

# The build farm runs `make dep` before building. Provision only what the VCV
# build needs: the monorepo submodule, then just its WDL sub-submodule (never
# JUCE or NeuralAmpModelerCore). Keyed on a real path so it runs once, and is a
# no-op when the Library checkout has already initialised the submodules.
DEPS += $(VCV)/src
$(VCV)/src:
	git submodule update --init --depth 1 $(OPC)
	git -C $(OPC) submodule update --init --depth 1 third_party/WDL

# plugin.mk packages DISTRIBUTABLES with path-preserving copy flags (rsync -rR /
# cp --parents), so `res` must be a top-level directory. Materialise it from the
# submodule at dist time; this keeps res single-source in the monorepo with no
# separate sync step. Regenerated on every clean build the farm performs.
dist: res
res: $(VCV)/src
	cp -r $(VCV)/res res

clean: clean-res
clean-res:
	rm -rf res

include $(RACK_DIR)/plugin.mk
