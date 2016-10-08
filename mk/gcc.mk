gcc_CHECKPOINT = $(VITASDK)/bin/arm-vita-eabi-g++*
gcc_CONFIGURE = script
gcc_CONFIGURE_DEPENDENCY = install-weak-newlib prepare-gcc-dependency
gcc_CONFIGURE_FLAGS = --enable-languages=c,c++ $(GCC_FLAGS)
gcc_DEPENDENCY = install-weak-vitalibs
gcc_REF = gcc-6-branch
gcc_SRC = https://github.com/vitasdk-experiment/gcc.git
gcc_TYPE = build-host
