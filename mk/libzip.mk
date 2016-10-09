libzip_CHECKPOINT = $(DEPENDENCY_PREFIX)/lib/libzip.a
libzip_CONFIGURE = script
libzip_CONFIGURE_FLAGS = --disable-shared CPPFLAGS=-DZIP_STATIC
libzip_SRC = https://github.com/vitasdk-experiment/libzip.git
libzip_SRC_REF = vita
libzip_TYPE = dependency
ifdef BUILD_DEPENDENCY
libzip_CONFIGURE_DEPENDENCY = prepare-weak-zlib
libzip_CONFIGURE_FLAGS += --with-zlib=$(DEPENDENCY_PREFIX)
endif
