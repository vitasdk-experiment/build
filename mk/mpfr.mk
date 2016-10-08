mpfr_CHECKPOINT = $(DEPENDENCY_PREFIX)/lib/libmpfr.a
mpfr_CONFIGURE = script
mpfr_SRC = http://www.mpfr.org/mpfr-current/mpfr-3.1.5.tar.xz
mpfr_SRC_SHA256 = 015fde82b3979fbe5f83501986d328331ba8ddf008c1ff3da3c238f49ca062bc
mpfr_TYPE = dependency
ifdef BUILD_DEPENDENCY
mpfr_CONFIGURE_DEPENDENCY = prepare-weak-gmp
mpfr_CONFIGURE_FLAGS = --with-gmp=$(DEPENDENCY_PREFIX)
endif
