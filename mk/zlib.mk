zlib_CHECKPOINT = $(DEPENDENCY_PREFIX)/lib/libz.a
zlib_SRC = sync-binutils-gdb
zlib_SRC_SUBDIR = zlib
zlib_TYPE = dependency
ifdef HOST_WIN
zlib_FLAGS = PREFIX=$(HOST_PREFIX)
zlib_MAKEFILE = win32/Makefile.gcc
zlib_OUTPUT = $(OUTPUT_SRC)/binutils-gdb/zlib
zlib_TARGET_INSTALL = $(VITASDK_HOST)/arm-vita-eabi/bin/zlib1.dll \
	       $(VITASDK_HOST)/bin/zlib1.dll
zlib_TARGET_PREPARE = $(DEPENDENCY_PREFIX)/include/zconf.h \
		      $(DEPENDENCY_PREFIX)/include/zlib.h \
		      $(DEPENDENCY_PREFIX)/lib/libz.a

$(VITASDK_HOST)/arm-vita-eabi/bin/zlib1.dll: $(zlib_OUTPUT)/zlib1.dll
	mkdir -p $(dir $@)
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(VITASDK_HOST)/bin/zlib1.dll: $(zlib_OUTPUT)/zlib1.dll
	mkdir -p $(dir $@)
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/include/zconf.h: $(zlib_OUTPUT)/zconf.h
	mkdir -p $(dir $@)
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/include/zlib.h: $(zlib_OUTPUT)/zlib.h
	mkdir -p $(dir $@)
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@

$(DEPENDENCY_PREFIX)/lib/libz.a: $(zlib_OUTPUT)/libz.dll.a
	mkdir -p $(dir $@)
	install -C$(if $(VERBOSITY_VERBOSE),v) $< $@
else
zlib_CONFIGURE = script
endif
