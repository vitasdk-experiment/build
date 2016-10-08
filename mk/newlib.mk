newlib_CHECKPOINT = $(VITASDK_HOST)/arm-vita-eabi/lib/libc.a
newlib_CONFIGURE = script
newlib_CONFIGURE_DEPENDENCY = install-weak-gcc-first
newlib_CONFIGURE_FLAGS = $(TOOLCHAIN_FLAGS)
newlib_DEPENDENCY = install-weak-vita-headers
newlib_REF = vita
newlib_SRC = https://github.com/vitasdk/newlib.git
