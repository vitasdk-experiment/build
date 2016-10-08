libelf_CHECKPOINT = $(DEPENDENCY_PREFIX)/lib/libelf.a
libelf_CONFIGURE = script
libelf_CONFIGURE_ENVIRONMENT = CC=$(CC)
libelf_SRC = https://github.com/vitasdk-experiment/libelf.git
libelf_TARGET_PREPARE = prepare-libelf-ranlib
libelf_TYPE = dependency

prepare-libelf-ranlib: $(DEPENDENCY_PREFIX)/lib/libelf.a
	$(HOST_PREFIX)ranlib $<

$(DEPENDENCY_PREFIX)/lib/libelf.a: $(OUTPUT_HOST)/libelf/install
