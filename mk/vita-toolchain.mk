vita-toolchain_CHECKPOINT = $(VITASDK)/bin/vita-libs-gen
vita-toolchain_CONFIGURE = CMake
vita-toolchain_CONFIGURE_FLAGS = -DDEFAULT_JSON=../share/db.json
vita-toolchain_SRC = https://github.com/vitasdk/vita-toolchain.git
vita-toolchain_TYPE = build-host
ifdef BUILD_DEPENDENCY
vita-toolchain_CONFIGURE_DEPENDENCY = prepare-weak-jansson prepare-weak-libelf \
				      prepare-weak-libzip prepare-weak-zlib
vita-toolchain_CONFIGURE_FLAGS += \
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
endif
