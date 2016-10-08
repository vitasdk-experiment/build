# vitasdk Experimental Buildscript
This is a buildscript for vitasdk as an alternative for the ARM Embedded
distribution. It has the following features:

* Automatic source synchronization
* Cross-compilation aware (e.g. Building a toolchain for MinGW on Linux)
* Extensible
* Incremental building
* No extra dependencies
* Parallel building
* Source code integrity check

# Requirements

* CMake
* GCC whose target is the building environment
* GCC whose target is the hosting environment
* Git
* GNU Bison
* GNU Coreutils
* GNU Make
* Shell
* Texinfo
* m4

It also requires the following programs if you specify
`BUILD_DEPENDENCY`:

* Tar
* Wget
* XZ Utils
* bzip2
* gzip

If you don't specify `BUILD_DEPENDENCY`, you need the following libraries:

* GNU GMP
* GNU MPC
* GNU MPFR
* Libelf

# Building

```
git clone https://github.com/vitasdk-experiment/build.git
export VITASDK=/path/to/the/directory/where/vitasdk/will/be/installed
make -C build -j$$(`nproc`*2) install
```

## Variables

`BUILD_DEPENDENCY`: Specify something to build dependencies. They will be
statically linked. It is useful for distributions.

`CMAKE`: Specify CMake executable.

`CMAKE_FLAGS`: Specify flags for CMake.

`DUMP`: Dump the intermediate expression of the specified component. Use for
debugging.

`HOST`: Specify the triplet of the machine which runs the built toolchain.

`OUTPUT`: Specify the path to the directory where you want to output the
intermediate files.

`V`: Specify to change the verbosity. 0 for the silent mode (but it's still
quite a noisy), 1 for the normal mode, 2 for the verbose mode.

`VITASDK_HOST`: The script uses the toolchain in `VITASDK`, but installs to
`VITASDK_HOST`. If you are cross-compiling, specify the path to the native
toolchain to `VITASDK` and the path to the target toolchain to `VITASDK_HOST`.

## Targets

`all`: Builds all components, but don't install if unnecessary to build.

`all-dependency`: Build all dependencies, but don't install if unnecessary to
		  build.

`install`: Install all components.

`sync`: Synchronize all components except dependencies.

`sync-dependency`: Synchronize dependencies.

`clean`: Clean all components.

`distclean`: Remove the whole outputs.

## Tips
For cross-compilation, build the toolchain for the building environment at
first, and then build the toolchain for the hosting environment with `HOST` and
`VITASDK_HOST` variables.

For building on MSYS2 or MinGW-w64, specify `"CMAKE_FLAGS=-G 'MSYS Makefiles'"`.
It should NOT be `MinGW Makefiles` because the Makefiles will be called from
the buildscript, which uses the shell. You should also set `HOST` if you
specify `BUILD_DEPENDENCY` because `configure` of libelf cannot guess the host.

# Adding a new component
Specify variables you need. Replace `component` with the name of component file
without suffix `.mk`.

`component_CHECKPOINT`: the file or directory to check if the component is
installed or prepared. If it doesn't exist, `install-weak-component` or
`prepare-weak-component` will be blank. If it exists or is not specified, those
targets are same with non-`weak` counterparts.

`component_CONFIGURE`: the configure type. _configure_ means to generate
`Makefile`. The available types are `CMake`, `script` (typically made with
autoconf), and `vita-libs-gen`. It will not configure if it is not specified.

`component_CONFIGURE_DEPENDENCY`: the targets which should be resolved before
configure. It MUST not be set if the configure type is `vita-libs-gen`.

`component_CONFIGURE_FLAGS`: the flags for configure. It MUST NOT be set
if `component_CONFIGURE` is not set.

`component_DEPENDENCY`: the targets which should be resolved before build.

`component_OUTPUT`: the directory to output intermediate files.

`component_SRC`: the source URL. The suffix determines how it should be handled.
The supported suffixes are `.git`, `.tar.bz2`, `.tar.gz`, and `.tar.xz`.

`component_SRC_REF`: the Git reference to the source, typically branch name or
tag name. The default value is `master`. It should be commit number in SHA-1 if
the source is not credible (i.e. the source is different from the source of this
buildscript), but such a reference is currently not supported. It MUST NOT be
set if the source is not Git.

`component_SRC_SHA256`: the SHA-256 hash of the source package. You MUST set
it for `.tar.bz2`, `.tar.gz` and `.tar.xz`, but NOT for `.git`.

`component_TARGET_ALL`: the targets to build all in the component. The targets
MUST be prefixed `all-component-`. Setting explicitly overrides the default
target.

`component_TAGRET_CLEAN`: the targets to clean the component. The targets MUST
be prefixed `all-component-`. Setting explicitly overrides the default target.

`component_TAGRET_INSTALL`: the targets to install the component. The targets
MUST be prefixed `install-component-`. Setting explicitly overrides the default
target.

`component_TAGRET_PREPARE`: the targets to prepare the component for other
components which depend on it. The targets must be prefixed
`prepare-component-`. Setting explicitly overrides the default target.

`component_TYPE`: the type of the component. The available types are
`build`, `build-host`, `dependency`, and `target`. `build` is for the build
machine. `build-host` is for the build and host machine. `dependency` is for the
dependencies of the build and host tools. `target` is for the components for the
target, namely PS Vita.
