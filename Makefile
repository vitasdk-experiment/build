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
HOST_FLAG := --host=$(HOST)

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

.PHONY: all clean distclean host install install-dependency sync \
	prepare-gcc-dependency install-vita-headers \
	$(VITASDK_HOST)/arm-vita-eabi/include

all: $(OUTPUT_HOST)/binutils-gdb/all $(OUTPUT_HOST)/gcc/all \
	$(OUTPUT_HOST)/vita-toolchain/all \
	$(OUTPUT_SRC)/pthread-embedded/platform/vita/all \
	$(OUTPUT_TARGET)/newlib/all $(OUTPUT_TARGET)/vitalibs/all

install: $(OUTPUT_HOST)/binutils-gdb/install $(OUTPUT_HOST)/gcc/install \
	$(OUTPUT_HOST)/vita-toolchain/install \
	$(OUTPUT_TARGET)/newlib/install \
	$(OUTPUT_SRC)/pthread-embedded/platform/vita/install \
	install-dependency install-vita-headers install-vitalibs

sync: sync-binutils-gdb sync-gcc sync-newlib sync-pthread-embedded \
	sync-vita-toolchain sync-vita-headers

sync-dependency: sync-gmp sync-jansson sync-libelf sync-libzip \
		 sync-mpc sync-mpfr

clean: $(OUTPUT_HOST)/binutils-gdb/clean $(OUTPUT_HOST)/gcc-first/clean \
	$(OUTPUT_HOST)/gcc/clean $(OUTPUT_HOST)/vita-toolchain/clean \
	$(OUTPUT_TARGET)/newlib/clean $(OUTPUT_TARGET)/vitalibs/clean \
	$(OUTPUT_SRC)/pthread-embedded/platform/vita/clean $(OUTPUT_ZLIB)/clean

distclean:
	$(RM) -R $(OUTPUT)

ifeq ($(wildcard $(VITASDK)/bin/arm-vita-eabi-gcc),)
ifeq ($(VITASDK),$(VITASDK_HOST))
build: $(OUTPUT_HOST)/binutils-gdb/install $(OUTPUT_HOST)/gcc-first/install
$(VITASDK)/bin/vita-libs-gen: $(OUTPUT_HOST)/vita-toolchain/install
else
$(error You need to install vitasdk to building machine at first.)
endif
else
build:
endif

define TARGET_STRIPPED
$1_MAKEFILE_F := $(if $4,$4,Makefile)
$1_MAKEFILE := $1/$$($1_MAKEFILE_F)

.PHONY: $1/%
$1/clean:
	if [ -f $$($1_MAKEFILE) ]; then cd $1; $$(MAKE)$(if $4, -f$$($1_MAKEFILE_F),) clean; fi

$1/install: $1/all
	cd $1; PATH='$(PATH):$(VITASDK)/bin' \
		$$(MAKE)$(if $4, -f$$($1_MAKEFILE_F),) install $2

$1/%: $$($1_MAKEFILE) $3
	cd $1; PATH='$(PATH):$(VITASDK)/bin' \
		$$(MAKE)$(if $4, -f$$($1_MAKEFILE_F),) $$(@:$1/%=%) $2
endef
TARGET = $(call TARGET_STRIPPED,$(strip $1),$(strip $2),$3,$(strip $4))

define SYNC_GIT_STRIPPED
.PHONY: sync-$1
sync-$1:
	if [ -d $(OUTPUT_SRC)/$1 ]; then \
		git -C $(OUTPUT_SRC)/$1 fetch$(if $(VERBOSITY_QUIET), -q,$(if $(VERBOSITY_VERBOSE), -v)) origin; \
		git -C $(OUTPUT_SRC)/$1 checkout$(if $(VERBOSITY_QUIET), -q) origin/$3; \
	else \
		git clone$(if $(VERBOSITY_QUIET), -q,$(if $(VERBOSITY_VERBOSE), -v)) $2 -b $3 $(OUTPUT_SRC)/$1; \
	fi
endef
SYNC_GIT = $(call SYNC_GIT_STRIPPED,$(strip $1),$(strip $2),$(strip $3))

define SYNC_WGET_TAR_STRIPPED
.PHONY: sync-$1
sync-$1: $(OUTPUT_SRC)/$(notdir $3)
	tar x$2$(if $(VERBOSITY_VERBOSE),v)C $(OUTPUT_SRC) -f $$<

.DELETE_ON_ERROR: $(OUTPUT_SRC)/$(notdir $3)
$(OUTPUT_SRC)/$(notdir $3):
	wget$(if $(VERBOSITY_VERBOSE), -q,$(if $(VERBOSITY_NORMAL), -nv)) $3 -O $$@
	sha256sum -c$(if $(VERBOSITY_VERBOSE), --quiet) <<< '$4 $$@'
endef
SYNC_WGET_TAR = $(call SYNC_WGET_TAR_STRIPPED,$(strip $1),$(strip $2),$(strip $3),$(strip $4))

define AUTOCONF_RULES_STRIPPED
$(call TARGET,$3/$1,,$7)
$3/$1/Makefile: $(OUTPUT_SRC)/$2/configure | $6 $3/$1
	cd $$(@D) && PATH='$(PATH):$(VITASDK)/bin' $5 ../../src/$2/configure $4

$(if $(AUTOCONF_SRC_$2),,
AUTOCONF_SRC_$2 := 1

$(if $(wildcard $(OUTPUT_SRC)/$2/configure),,
$(OUTPUT_SRC)/$2/configure:
	$$(MAKE) sync-$1
)
)

$3/$1:
	mkdir -p$(if $(VERBOSITY_VERBOSE),v) $$@
endef
AUTOCONF_RULES = $(call AUTOCONF_RULES_STRIPPED,$(strip $1),$(strip $2),$(strip $3),$(strip $4),$(strip $5),$(strip $6),$(strip $7))

DEPENDENCY_PREFIX := $(abspath $(OUTPUT_HOST)/dependency)

ifdef BUILD_DEPENDENCY
BINUTILS_GDB_DEPENDENCY_FLAGS := --with-system-zlib CFLAGS=-I$(DEPENDENCY_PREFIX)/include LDFLAGS=-L$(DEPENDENCY_PREFIX)/lib

GCC_DEPENDENCY_FLAGS := --with-gmp=$(DEPENDENCY_PREFIX) \
			--with-mpc=$(DEPENDENCY_PREFIX) \
			--with-mpfr=$(DEPENDENCY_PREFIX)

MPC_DEPENDENCY_FLAGS := --with-gmp=$(DEPENDENCY_PREFIX) \
			--with-mpfr=$(DEPENDENCY_PREFIX)

MPFR_DEPENDENCY_FLAGS := --with-gmp=$(DEPENDENCY_PREFIX)

VITA_TOOLCHAIN_DEPENDENCY_FLAGS := \
	-DJansson_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include \
	-DJansson_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libjansson.a \
	-DZIP_STATIC=1 \
	-Dlibelf_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include/libelf \
	-Dlibelf_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libelf.a \
	-Dlibzip_CONFIG_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/lib/libzip/include \
	-Dlibzip_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include \
	-Dlibzip_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libzip.a \
	-Dzlib_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include \
	-Dzlib_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libz.a

LIBZIP_DEPENDENCY_FLAGS := \
	-DZLIB_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include \
	-DZLIB_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libz.a

install-dependency: install-zlib

prepare-binutils-gdb-dependency: prepare-zlib
prepare-gcc-dependency: prepare-gmp prepare-mpc prepare-mpfr
prepare-libzip-dependency: prepare-zlib
prepare-mpc-dependency: prepare-gmp prepare-mpfr
prepare-mpfr-dependency: prepare-gmp
prepare-vita-toolchain-dependency: \
	prepare-jansson prepare-libelf prepare-libzip prepare-zlib
else
prepare-binutils-gdb-dependency:
prepare-gcc-dependency:
prepare-vita-toolchain-dependency:
prepare-mpc-dependency:
prepare-mpfr-dependency:
endif

.PHONY: prepare-gmp prepare-mpfr

ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libgmp.a),)
prepare-gmp: $(OUTPUT_HOST)/gmp/install
else
prepare-gmp:
endif
ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libhansson.a),)
prepare-jansson: $(OUTPUT_HOST)/jansson/install
else
prepare-jansson:
endif
ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libelf.a),)
prepare-libelf: $(OUTPUT_HOST)/libelf/install
	$(HOST_PREFIX)ranlib $(DEPENDENCY_PREFIX)/lib/libelf.a
else
prepare-libelf:
endif
ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libzip.a),)
prepare-libzip: $(OUTPUT_HOST)/libzip/install
else
prepare-libzip:
endif
ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libmpc.a),)
prepare-mpc: $(OUTPUT_HOST)/mpc/install
else
prepare-mpc:
endif
ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libmpfr.a),)
prepare-mpfr: $(OUTPUT_HOST)/mpfr/install
else
prepare-mpfr:
endif

sync-dependency: sync-gmp sync-libelf sync-libzip sync-mpc sync-mpfr

$(DEPENDENCY_PREFIX)/include:
	mkdir -p$(if $(VERBOSITY_VERBOSE),v) $@

$(DEPENDENCY_PREFIX)/lib:
	mkdir -p$(if $(VERBOSITY_VERBOSE),v) $@

install-vita-headers: $(VITASDK_HOST)/arm-vita-eabi/include \
		      $(VITASDK_HOST)/share/db.json
install-vitalibs: $(VITASDK_HOST)/arm-vita-eabi/lib

$(VITASDK_HOST)/share/db.json: $(OUTPUT_SRC)/vita-headers
	install -CD$(if $(VERBOSITY_VERBOSE),v) $< $@

$(VITASDK_HOST)/arm-vita-eabi/bin:
	mkdir -p$(if $(VERBOSITY_VERBOSE),v) $@

$(VITASDK_HOST)/arm-vita-eabi/include: $(OUTPUT_SRC)/vita-headers
	mkdir -p $@
	cp -RTfu$(if $(VERBOSITY_VERBOSE),v) $</include $@

$(VITASDK_HOST)/arm-vita-eabi/lib: $(OUTPUT_TARGET)/vitalibs/all
	install -CD$(if $(VERBOSITY_VERBOSE),v) $(OUTPUT_TARGET)/vitalibs/*.a -t $@

$(VITASDK_HOST)/bin:
	mkdir -p$(if $(VERBOSITY_VERBOSE),v) $@

ifeq ($(wildcard $(OUTPUT_SRC)/vita-headers),)
$(OUTPUT_SRC)/vita-headers: sync-vita-headers
endif

$(eval $(call TARGET,$(OUTPUT_SRC)/pthread-embedded/platform/vita, \
		     PREFIX=$(VITASDK)/arm-vita-eabi, \
		     $(OUTPUT_HOST)/gcc/install))

$(OUTPUT_SRC)/pthread-embedded/platform/vita/Makefile: \
	$(if $(wildcard $(OUTPUT_SRC)/pthread-embedded/platform/vita/Makefile),, \
		sync-pthread-embedded)
	:

$(eval $(call TARGET,$(OUTPUT_TARGET)/vitalibs,,build))

$(OUTPUT_TARGET)/vitalibs/Makefile: $(VITASDK)/bin/vita-libs-gen \
				    $(OUTPUT_SRC)/vita-headers
	mkdir -p $(@D)
	$< $(OUTPUT_SRC)/vita-headers/db.json $(@D)

HOST_CMAKE = -G 'Unix Makefiles'
ifdef HOST_WIN
HOST_CMAKE += -DCMAKE_SYSTEM_NAME=Windows
endif

ifdef HOST_PREFIX
HOST_CMAKE += -DCMAKE_C_COMPILER=$(CC) -DCMAKE_CXX_COMPILER=$(CXX)
endif

$(eval $(call TARGET,$(OUTPUT_HOST)/vita-toolchain,$(if $(VERBOSITY_QUIET),,VERBOSE=1)))

$(OUTPUT_HOST)/vita-toolchain/Makefile: $(OUTPUT_SRC)/vita-toolchain \
					| $(OUTPUT_HOST)/vita-toolchain \
					  prepare-vita-toolchain-dependency
	cd $(@D) && $(CMAKE) ../../src/vita-toolchain \
		-DCMAKE_INSTALL_PREFIX=$(VITASDK_HOST) \
		-DDEFAULT_JSON=../share/db.json \
		$(CMAKE_FLAGS) $(VITA_TOOLCHAIN_DEPENDENCY_FLAGS) $(HOST_CMAKE)

$(OUTPUT_HOST)/vita-toolchain:
	mkdir -p $@

ifeq ($(wildcard $(OUTPUT_SRC)/vita-toolchain),)
$(OUTPUT_SRC)/vita-toolchain: sync-vita-toolchain
endif

DEPENDENCY_FLAGS := --disable-shared $(HOST_FLAG) --prefix=$(DEPENDENCY_PREFIX)

$(eval $(call TARGET,$(OUTPUT_HOST)/libzip,,$(if $(VERBOSITY_QUIET),,VERBOSE=1)))

$(OUTPUT_HOST)/libzip/Makefile: $(OUTPUT_SRC)/libzip \
				| $(OUTPUT_HOST)/libzip \
				  prepare-libzip-dependency
	cd $(@D) && $(CMAKE) ../../src/libzip \
		-DCMAKE_C_FLAGS=-DZIP_STATIC \
		-DCMAKE_INSTALL_PREFIX=$(DEPENDENCY_PREFIX) \
		$(LIBZIP_DEPENDENCY_FLAGS) $(HOST_CMAKE)

$(OUTPUT_HOST)/libzip:
	mkdir -p $@

ifeq ($(wildcard $(OUTPUT_SRC)/libzip),)
$(OUTPUT_SRC)/libzip: sync-libzip
endif

$(eval $(call AUTOCONF_RULES, \
	gmp,gmp-6.1.1,$(OUTPUT_HOST), \
	$(DEPENDENCY_FLAGS)))
$(eval $(call AUTOCONF_RULES, \
	jansson,jansson-2.9,$(OUTPUT_HOST), \
	$(DEPENDENCY_FLAGS)))
$(eval $(call AUTOCONF_RULES, \
	libelf,libelf,$(OUTPUT_HOST), \
	$(DEPENDENCY_FLAGS),CC=$(CC)))
$(eval $(call AUTOCONF_RULES, \
	mpc,mpc-1.0.3,$(OUTPUT_HOST), \
	$(DEPENDENCY_FLAGS) $(MPC_DEPENDENCY_FLAGS),,prepare-mpc-dependency))
$(eval $(call AUTOCONF_RULES, \
	mpfr,mpfr-3.1.5,$(OUTPUT_HOST), \
	$(DEPENDENCY_FLAGS) $(MPFR_DEPENDENCY_FLAGS),,prepare-mpfr-dependency))

ifdef HOST_WIN
.PHONY: $(VITASDK_HOST)/arm-vita-eabi/bin/zlib1.dll \
	$(VITASDK_HOST)/bin/zlib1.dll

install-zlib: $(VITASDK_HOST)/arm-vita-eabi/bin/zlib1.dll \
	      $(VITASDK_HOST)/bin/zlib1.dll
prepare-zlib: $(DEPENDENCY_PREFIX)/include/zconf.h \
	      $(DEPENDENCY_PREFIX)/include/zlib.h \
	      $(DEPENDENCY_PREFIX)/lib/libz.a

$(VITASDK_HOST)/arm-vita-eabi/bin/zlib1.dll: $(OUTPUT_ZLIB)/zlib1.dll \
					     | $(VITASDK_HOST)/arm-vita-eabi/bin
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(VITASDK_HOST)/bin/zlib1.dll: $(OUTPUT_ZLIB)/zlib1.dll | $(VITASDK_HOST)/bin
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/include/zconf.h: $(OUTPUT_ZLIB)/zconf.h \
				      | $(DEPENDENCY_PREFIX)/include
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/include/zlib.h: $(OUTPUT_ZLIB)/zlib.h \
				     | $(DEPENDENCY_PREFIX)/include
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/lib/libz.a: $(OUTPUT_ZLIB)/libz.dll.a \
				 | $(DEPENDENCY_PREFIX)/lib
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(eval $(call TARGET,$(OUTPUT_ZLIB),PREFIX=$(HOST_PREFIX),,win32/Makefile.gcc))
else
$(eval $(call AUTOCONF_RULES,zlib,binutils-gdb/zlib),$(OUTPUT_HOST), \
			     $(DEPENDENCY_FLAGS))
install-zlib:
prepare-zlib: $(DEPENDENCY_PREFIX)/lib/libz.a

ifeq ($(wildcard $(DEPENDENCY_PREFIX)/lib/libz.a),)
$(DEPENDENCY_PREFIX)/lib/libz.a: $(OUTPUT_ZLIB)/install
endif
endif

PREFIX_FLAG := --prefix=$(abspath $(VITASDK_HOST))
TARGET_FLAG := --target=arm-vita-eabi
TOOLCHAIN_FLAGS := $(HOST_FLAG) $(PREFIX_FLAG) $(TARGET_FLAG)

$(eval $(call AUTOCONF_RULES, \
	binutils-gdb,binutils-gdb,$(OUTPUT_HOST), \
	$(TOOLCHAIN_FLAGS) $(BINUTILS_GDB_DEPENDENCY_FLAGS),,, \
	prepare-binutils-gdb-dependency))

GCC_ARCH_FLAGS := --with-cpu=cortex-a9 --with-fpu=neon-fp16
GCC_FLAGS := --disable-shared --with-newlib \
	     $(GCC_ARCH_FLAGS) $(GCC_DEPENDENCY_FLAGS) $(TOOLCHAIN_FLAGS)
GCC_FIRST_FLAGS := --disable-libssp --enable-languages=c $(GCC_FLAGS)
GCC_FINAL_FLAGS := --enable-languages=c,c++ $(GCC_FLAGS)

$(eval $(call AUTOCONF_RULES, \
	gcc-first,gcc,$(OUTPUT_HOST),$(GCC_FIRST_FLAGS),, \
	$(OUTPUT_HOST)/binutils-gdb/install prepare-gcc-dependency))
$(eval $(call AUTOCONF_RULES, \
	gcc,gcc,$(OUTPUT_HOST),$(GCC_FINAL_FLAGS),, \
	$(VITASDK)/arm-vita-eabi/lib/libc.a prepare-gcc-dependency, \
	install-vitalibs))

ifeq ($(wildcard $(VITASDK)/arm-vita-eabi/lib/libc.a),)
$(VITASDK)/arm-vita-eabi/lib/libc.a: $(OUTPUT_TARGET)/newlib/install
endif

$(eval $(call AUTOCONF_RULES,newlib,newlib,$(OUTPUT_TARGET), \
			     $(TOOLCHAIN_FLAGS),,build, \
			     $(VITASDK_HOST)/arm-vita-eabi/include))

$(eval $(call SYNC_WGET_TAR, \
	gmp,J, \
	https://gmplib.org/download/gmp/gmp-6.1.1.tar.xz, \
	d36e9c05df488ad630fff17edb50051d6432357f9ce04e34a09b3d818825e831))
$(eval $(call SYNC_WGET_TAR, \
	jansson,j, \
	http://www.digip.org/jansson/releases/jansson-2.9.tar.bz2, \
	77094fc1e113da0e2e65479488a0719f859b8f5bde3a6a0da88a1c73a88b5698))
$(eval $(call SYNC_GIT, \
	libelf, \
	https://github.com/vitasdk-experiment/libelf.git, \
	master))
$(eval $(call SYNC_GIT, \
	libzip, \
	https://github.com/vitasdk-experiment/libzip.git, \
	vita))
$(eval $(call SYNC_WGET_TAR, \
	mpc,z, \
	ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz, \
	617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3))
$(eval $(call SYNC_WGET_TAR, \
	mpfr,J, \
	http://www.mpfr.org/mpfr-current/mpfr-3.1.5.tar.xz, \
	015fde82b3979fbe5f83501986d328331ba8ddf008c1ff3da3c238f49ca062bc))

$(OUTPUT_SRC)/binutils-gdb/zlib/win32/Makefile.gcc: \
	$(if $(wildcard $(OUTPUT_SRC)/binutils-gdb/zlib/win32/Makefile.gcc),, \
		sync-binutils-gdb)
	:

.PHONY: sync-gcc-first sync-zlib
sync-gcc-first: sync-gcc
sync-zlib: sync-binutils-gdb

$(eval $(call SYNC_GIT,binutils-gdb, \
		       https://github.com/vitasdk-experiment/binutils-gdb.git, \
		       binutils-2_27-branch))
$(eval $(call SYNC_GIT,gcc, \
		       https://github.com/vitasdk-experiment/gcc.git, \
		       gcc-6-branch))
$(eval $(call SYNC_GIT,newlib, \
		       https://github.com/vitasdk/newlib.git, \
		       vita))
$(eval $(call SYNC_GIT,pthread-embedded, \
		       https://github.com/vitasdk/pthread-embedded.git, \
		       master))
$(eval $(call SYNC_GIT,vita-toolchain, \
		       https://github.com/vitasdk/vita-toolchain.git, \
		       master))
$(eval $(call SYNC_GIT,vita-headers, \
		       https://github.com/vitasdk/vita-headers.git, \
		       master))
