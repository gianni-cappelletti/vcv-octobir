# OctobIR - VCV Rack Library packaging repository.
#
# Source of truth is the October Production Co. monorepo, pinned here as the
# `opc` submodule. This repository exists only so the VCV Library build farm
# sees a standard Rack plugin (plugin.json + Makefile) at the repository root,
# which the rack-plugin-toolchain requires. No source is duplicated: a release
# is a bump of the `opc` submodule pointer plus a version bump in plugin.json.

RACK_DIR ?= ../Rack

# Pull in Rack's arch detection (ARCH_WIN / ARCH_MAC / ARCH_LIN / ARCH_ARM64)
# before we use it below; these are not defined until this is included.
include $(RACK_DIR)/arch.mk

OPC := opc
VCV := $(OPC)/plugins/octobir/vcv-rack
PFFFT := $(OPC)/third_party/pffft

FLAGS += -I$(OPC)/libs/octobir-core/include
FLAGS += -I$(OPC)/third_party/WDL/WDL
FLAGS += -I$(OPC)/third_party
FLAGS += -I$(PFFFT)/include/pffft

# WDL static-asserts that `char` is signed. On ARM (mac-arm64, a Library build
# target) `char` is unsigned by default, tripping the assertion. Force signed
# `char` so all architectures agree; a no-op on x86 where signed is the default.
FLAGS += -fsigned-char

# pffft.h declares its API __declspec(dllimport) unless PFFFT_STATIC_DEFINE is
# set. We link pffft statically into the plugin, so define it on Windows to
# avoid dllimport'd declarations against local definitions (matches the WIN32
# path in octobir-core/CMakeLists.txt).
ifdef ARCH_WIN
FLAGS += -DPFFFT_STATIC_DEFINE
endif

# Enable pffft's NEON SIMD path on arm64 (mac-arm64 is a Library target);
# without it pffft compiles a scalar fallback.
ifdef ARCH_ARM64
FLAGS += -DPFFFT_ENABLE_NEON=1
endif

SOURCES += $(wildcard $(VCV)/src/*.cpp)
SOURCES += $(OPC)/libs/octobir-core/src/IRLoader.cpp
SOURCES += $(OPC)/libs/octobir-core/src/IRProcessor.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/convoengine.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/resample.cpp
SOURCES += $(OPC)/third_party/WDL/WDL/fft.c

# IRLoader.cpp uses pffft for its minimum-phase (cepstrum) IR conversion.
SOURCES += $(PFFFT)/src/pffft.c
SOURCES += $(PFFFT)/src/pffft_common.c

DISTRIBUTABLES += res
DISTRIBUTABLES += $(wildcard LICENSE*)

# The build farm runs `make dep` before building. Provision only what the VCV
# build needs: the monorepo submodule, then its WDL and pffft sub-submodules
# (never JUCE or NeuralAmpModelerCore). Keyed on a real path so it runs once,
# and is a no-op when the Library checkout has already initialised the submodules.
DEPS += $(VCV)/src
$(VCV)/src:
	git submodule update --init --depth 1 $(OPC)
	git -C $(OPC) submodule update --init --depth 1 third_party/WDL third_party/pffft

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
