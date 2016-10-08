mpc_CHECKPOINT = $(DEPENDENCY_PREFIX)/lib/libmpc.a
mpc_CONFIGURE = script
mpc_SRC = ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
mpc_SRC_SHA256 = 617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3
mpc_TYPE = dependency
ifdef BUILD_DEPENDENCY
mpc_CONFIGURE_FLAGS = --with-gmp=$(DEPENDENCY_PREFIX) \
		      --with-mpfr=$(DEPENDENCY_PREFIX)
mpc_CONFIGURE_DEPENDENCY = prepare-weak-gmp prepare-weak-mpfr
endif
