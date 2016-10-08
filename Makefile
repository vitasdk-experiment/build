# Copyright (C) 2016 173210  <root.3.173210@live.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ifndef VITASDK
$(error VITASDK is not set. set VITASDK to the directory which vitasdk will be installed to)
endif

ifndef HOST
HOST = $(shell $(CC) -dumpmachine)
else ifeq ($(shell which $(HOST)-gcc),)
HOST_PREFIX =
else
HOST_PREFIX = $(HOST)-
CC := $(HOST_PREFIX)gcc
CXX := $(HOST_PREFIX)g++
endif

ifneq ($(strip $(foreach pattern,cygwin mingw, \
				 $(findstring $(pattern),$(HOST)))),)
HOST_WIN := 1
endif

CMAKE = cmake
VITASDK_HOST = $(VITASDK)

V = 0
ifeq ($(V),0)
VERBOSITY_QUIET := 1
else ifeq ($(V),1)
VERBOSITY_NORMAL := 1
else
VERBOSITY_VERBOSE := 1
endif

OUTPUT = output
OUTPUT_HOST := $(OUTPUT)/host-$(HOST)
OUTPUT_SRC := $(OUTPUT)/src
OUTPUT_TARGET := $(OUTPUT)/target
ifdef HOST_WIN
OUTPUT_ZLIB = $(OUTPUT)/src/binutils-gdb/zlib
else
OUTPUT_ZLIB = $(OUTPUT_HOST)/binutils-gdb/zlib
endif

ifeq ($(wildcard $(OUTPUT)/prefix.mk),)
$(shell echo 'VITASDK_HOST_PREVIOUS := $(VITASDK_HOST)' > $(OUTPUT)/prefix.mk)
else
include $(OUTPUT)/prefix.mk
ifneq ($(VITASDK_HOST),$(VITASDK_HOST_PREVIOUS))
$(error VITASDK_HOST differs from the last build. Please run target `distclean'.)
endif
endif

.PHONY: all build build-early clean distclean host install \
	sync sync-dependency prepare-gcc-dependency

all:

distclean:
	$(RM) -R $(OUTPUT)

$(VITASDK)/bin/vita-libs-gen: | install-vita-toolchain

DEPENDENCY_PREFIX := $(abspath $(OUTPUT_HOST)/dependency)

ifdef BUILD_DEPENDENCY
GCC_DEPENDENCY_FLAGS := --with-gmp=$(DEPENDENCY_PREFIX) \
			--with-mpc=$(DEPENDENCY_PREFIX) \
			--with-mpfr=$(DEPENDENCY_PREFIX)

prepare-gcc-dependency: prepare-weak-gmp prepare-weak-mpc prepare-weak-mpfr
else
prepare-gcc-dependency:
endif

HOST_CMAKE = -G 'Unix Makefiles'
ifdef HOST_WIN
HOST_CMAKE += -DCMAKE_SYSTEM_NAME=Windows
endif
ifdef HOST_PREFIX
HOST_CMAKE += -DCMAKE_C_COMPILER=$(CC) -DCMAKE_CXX_COMPILER=$(CXX)
endif

TOOLCHAIN_FLAGS := --host=$(HOST) --prefix=$(abspath $(VITASDK_HOST)) \
		   --target=arm-vita-eabi

GCC_FLAGS := --disable-shared --with-cpu=cortex-a9 --with-fpu=neon-fp16 \
	     --with-newlib $(GCC_DEPENDENCY_FLAGS) $(TOOLCHAIN_FLAGS)

define LOAD_COMPONENT
# BEGINNING OF LINE
include mk/$1.mk

ifndef $1_OUTPUT
ifeq ($$(findstring $$($1_TYPE),build build-host dependency),)
$1_OUTPUT_PARENT := $(OUTPUT_TARGET)
else
$1_OUTPUT_PARENT := $(OUTPUT_HOST)
endif
$1_OUTPUT := $$($1_OUTPUT_PARENT)/$1
endif

ifneq ($$(filter sync-%,$$($1_SRC)),)
$1_SRC_DIR := $$($1_SRC:sync-%=%)$$(if $$($1_SRC_SUBDIR),/$$($1_SRC_SUBDIR))
sync-$1: $$($1_SRC)
else
$1_SRC_SUFFIX := $$(suffix $$($1_SRC))

.PHONY: sync-$1
ifeq ($$($1_SRC_SUFFIX),.git)
$1_SRC_DIR := $1
$1_SRC_REF ?= master

sync-$1:
	if [ -d $(OUTPUT_SRC)/$$($1_SRC_DIR) ]; then \
		git -C $(OUTPUT_SRC)/$$($1_SRC_DIR) \
			fetch$(if $(VERBOSITY_QUIET), -q,$(if $(VERBOSITY_VERBOSE), -v)) origin; \
		git -C $(OUTPUT_SRC)/$$($1_SRC_DIR) \
			checkout$(if $(VERBOSITY_QUIET), -q) origin/$$($1_SRC_REF); \
	else \
		git clone$(if $(VERBOSITY_QUIET), -q,$(if $(VERBOSITY_VERBOSE), -v)) \
			$$($1_SRC) -b $$($1_SRC_REF) $(OUTPUT_SRC)/$$($1_SRC_DIR); \
	fi
else ifeq ($$(suffix $$($1_SRC:%$$($1_SRC_SUFFIX)=%)),.tar)
$1_SRC_DIR := $$(patsubst %.tar,%,$$(notdir $$($1_SRC:%$$($1_SRC_SUFFIX)=%)))

ifeq ($$($1_SRC_SUFFIX),.bz2)
$1_SRC_FILTER := j
else ifeq ($$($1_SRC_SUFFIX),.gz)
$1_SRC_FILTER := z
else ifeq ($$($1_SRC_SUFFIX),.xz)
$1_SRC_FILTER := J
else
$$(error $1: unknown compression)
endif

sync-$1: $(OUTPUT_SRC)/$$(notdir $$($1_SRC))
	tar x$$($1_SRC_FILTER)$(if $(VERBOSITY_VERBOSE),v)C $(OUTPUT_SRC) -f $$<

.DELETE_ON_ERROR: $(OUTPUT_SRC)/$$(notdir $$($1_SRC))
$(OUTPUT_SRC)/$$(notdir $$($1_SRC)):
	wget$(if $(VERBOSITY_VERBOSE), -q,$(if $(VERBOSITY_NORMAL), -nv)) \
		$$($1_SRC) -O $$@
	sha256sum -c$(if $(VERBOSITY_VERBOSE), --quiet) \
		<<< '$$($1_SRC_SHA256) $$@'
else
$$(error $1: unknown source type)
endif
endif

ifndef $1_CONFIGURE
$1_MAKEFILE ?= Makefile
$$($1_OUTPUT)/$$($1_MAKEFILE): \
	$$(if $$(wildcard $$($1_OUTPUT)/$$($1_MAKEFILE)),,sync-$1);
else ifeq ($$($1_CONFIGURE),CMake)
ifeq ($(VERBOSITY_QUIET),)
$1_FLAGS += VERBOSE=1
endif
ifeq ($$($1_TYPE),dependency)
$1_CONFIGURE_FLAGS += -DCMAKE_INSTALL_PREFIX=$(DEPENDENCY_PREFIX) $(HOST_CMAKE)
else ifneq ($$(findstring $$($1_TYPE),build-host),)
$1_CONFIGURE_FLAGS += -DCMAKE_INSTALL_PREFIX=$(VITASDK_HOST) $(HOST_CMAKE)
endif
$1_MAKEFILE := Makefile

$$($1_OUTPUT)/Makefile: $$(if $$(wildcard $(OUTPUT_SRC)/$$($1_SRC_DIR)),,sync-$1) \
			| $$($1_CONFIGURE_DEPENDENCY)
	mkdir -p $$(@D)
	cd $$(@D) && $(CMAKE) ../../src/$$($1_SRC_DIR) $$($1_CONFIGURE_FLAGS)
else ifeq ($$($1_CONFIGURE),script)
ifeq ($$($1_TYPE),dependency)
$1_CONFIGURE_FLAGS += --disable-shared --host=$(HOST) \
		      --prefix=$(DEPENDENCY_PREFIX)
endif
$1_MAKEFILE := Makefile

$$($1_OUTPUT)/Makefile: $(OUTPUT_SRC)/$$($1_SRC_DIR)/configure \
			| $$($1_CONFIGURE_DEPENDENCY)
	mkdir -p $$(@D)
	cd $$(@D) && \
		PATH='$(PATH):$(VITASDK)/bin' $$($1_CONFIGURE_ENVIRONMENT) \
		../../src/$$($1_SRC_DIR)/configure $$($1_CONFIGURE_FLAGS)
ifeq ($$(wildcard $(OUTPUT_SRC)/$$($1_SRC_DIR)/configure),)
$(OUTPUT_SRC)/$$($1_SRC_DIR)/configure: sync-$1
endif
else ifeq ($$($1_CONFIGURE),vita-libs-gen)
$1_MAKEFILE := Makefile
$1_TARGET_INSTALL := install-vitalibs-$1

$$($1_OUTPUT)/Makefile: $(VITASDK)/bin/vita-libs-gen \
			$(OUTPUT_SRC)/$$($1_SRC_DIR)/db.json
	mkdir -p $$(@D)
	$$^ $$(@D)

.PHONY: install-vitalibs-$1
install-vitalibs-$1: $$($1_OUTPUT)/all
	install -CD$(if $(VERBOSITY_VERBOSE),v) \
		$$($1_OUTPUT)/*.a -t $(VITASDK_HOST)/arm-vita-eabi/lib
else
$$(error $1: unknown configure type)
endif

.NOTPARALLEL: $$($1_OUTPUT)/%

$$($1_OUTPUT)/clean:
	if [ -f $$($1_OUTPUT)/$$($1_MAKEFILE) ]; then \
		cd $$($1_OUTPUT); \
			$$(MAKE) -f$$($1_MAKEFILE) clean $$($1_FLAGS); \
	fi

.PHONY: $$($1_OUTPUT)/%
$$($1_OUTPUT)/%: $$($1_OUTPUT)/$$($1_MAKEFILE) $$($1_DEPENDENCY)
	cd $$($1_OUTPUT); PATH='$(PATH):$(VITASDK)/bin' \
		$$(MAKE) -f$$($1_MAKEFILE) $$(@:$$($1_OUTPUT)/%=%) $$($1_FLAGS)

$1_TARGET_ALL ?= $$($1_OUTPUT)/all
$1_TARGET_CLEAN ?= $$($1_OUTPUT)/clean
ifeq ($$($1_TYPE),dependency)
$1_TARGET_PREPARE ?= all-$1 $$($1_OUTPUT)/install
else
$1_TARGET_INSTALL ?= all-$1 $$($1_OUTPUT)/install
endif

.PHONY: all-$1 clean-$1
all-$1: $$($1_TARGET_ALL)
clean-$1: $$($1_TARGET_CLEAN)
clean: clean-$1

.PHONY: install-$1
install-$1: $$($1_TARGET_INSTALL)

.PHONY: prepare-$1
prepare-$1: $$($1_TARGET_PREPARE)

.PHONY: install-weak-$1 prepare-weak-$1
ifndef $1_CHECKPOINT
install-weak-$1: $$($1_TARGET_INSTALL)
prepare-weak-$1: $$($1_TARGET_PREPARE)
else ifeq ($$(wildcard $$($1_CHECKPOINT)),)
ifneq ($$(findstring $$($1_TYPE),build build-host),)
ifneq ($(VITASDK),$(VITASDK_HOST))
$$(error install vitasdk to building machine at first)
endif
endif
install-weak-$1: $$($1_TARGET_INSTALL)
prepare-weak-$1: $$($1_TARGET_PREPARE)
else
install-weak-$1:
prepare-weak-$1:
endif

ifeq ($$($1_TYPE),dependency)
all-dependency: all-$1
install-dependency: install-$1
prepare-dependency: prepare-$1
sync-dependency: sync-$1
else ifneq ($$($1_TYPE),build)
all: all-$1
install: install-$1
prepare: prepare-$1
sync: sync-$1
endif
endef

$(eval $(foreach component,$(patsubst mk/%.mk,%,$(wildcard mk/*.mk)), \
			   $(call LOAD_COMPONENT,$(component))))

ifdef BUILD_DEPENDENCY
all: all-dependency
install: install-dependency
sync: sync-dependency
endif

ifdef DUMP
$(warning $(call LOAD_COMPONENT,$(DUMP)))
endif
