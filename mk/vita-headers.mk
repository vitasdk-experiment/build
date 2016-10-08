vita-headers_SRC = https://github.com/vitasdk/vita-headers.git
vita-headers_TARGET_ALL =
vita-headers_TARGET_CLEAN =
vita-headers_TARGET_INSTALL = install-vita-headers-include \
			      $(VITASDK_HOST)/share/db.json

.PHONY: install-vita-headers-include
install-vita-headers-include: $(OUTPUT_SRC)/vita-headers
	mkdir -p $(VITASDK_HOST)/arm-vita-eabi/include
	cp -RTfu$(if $(VERBOSITY_VERBOSE),v) \
		$</include $(VITASDK_HOST)/arm-vita-eabi/include

$(VITASDK_HOST)/share/db.json: $(OUTPUT_SRC)/vita-headers/db.json
	install -CD$(if $(VERBOSITY_VERBOSE),v) $< $@

ifeq ($(wildcard $(OUTPUT_SRC)/vita-headers),)
$(OUTPUT_SRC)/vita-headers: sync-vita-headers
$(OUTPUT_SRC)/vita-headers/db.json: sync-vita-headers
endif
