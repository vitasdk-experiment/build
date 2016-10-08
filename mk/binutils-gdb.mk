binutils-gdb_CHECKPOINT = $(VITASDK)/bin/arm-vita-eabi-as*
binutils-gdb_CONFIGURE = script
binutils-gdb_CONFIGURE_FLAGS = $(TOOLCHAIN_FLAGS)
binutils-gdb_REF = binutils-2_27-branch
binutils-gdb_SRC = https://github.com/vitasdk-experiment/binutils-gdb.git
binutils-gdb_TYPE = build-host
ifdef BUILD_DEPENDENCY
binutils-gdb_CONFIGURE_DEPENDENCY = prepare-weak-zlib
binutils-gdb_CONFIGURE_FLAGS += --with-system-zlib \
				 CFLAGS=-I$(DEPENDENCY_PREFIX)/include \
				 LDFLAGS=-L$(DEPENDENCY_PREFIX)/lib
endif
