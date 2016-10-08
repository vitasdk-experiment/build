gcc-first_CHECKPOINT = $(VITASDK)/bin/arm-vita-eabi-gcc*
gcc-first_CONFIGURE = script
gcc-first_CONFIGURE_DEPENDENCY = install-weak-binutils-gdb \
				 prepare-gcc-dependency
gcc-first_CONFIGURE_FLAGS = --disable-libssp --enable-languages=c $(GCC_FLAGS)
gcc-first_SRC = sync-gcc
gcc-first_TYPE = build
