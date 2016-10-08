libzip_CONFIGURE = CMake
libzip_CONFIGURE_FLAGS = -DCMAKE_C_FLAGS=-DZIP_STATIC
libzip_SRC = https://github.com/vitasdk-experiment/libzip.git
libzip_SRC_REF = vita
libzip_TYPE = dependency
ifdef BUILD_DEPENDENCY
libzip_CONFIGURE_DEPENDENCY = prepare-weak-zlib
libzip_CONFIGURE_FLAGS += \
	-DZLIB_INCLUDE_DIR=$(DEPENDENCY_PREFIX)/include \
	-DZLIB_LIBRARY=$(DEPENDENCY_PREFIX)/lib/libz.a
endif
