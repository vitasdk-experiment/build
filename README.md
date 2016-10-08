# vitasdk Experimental Buildscript
This is a buildscript for vitasdk as an alternative for the ARM Embedded
distribution. It has the following features:

* Automatic source synchronization
* Cross-compilation aware (e.g. Building a toolchain for MinGW on Linux)
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

`install`: Install all components

`sync`: Synchronize all components except dependencies

`sync-dependency`: Synchronize dependencies

`clean`: Clean all components

`distclean`: Remove the whole outputs

`output/host-HOST_TRIPLET/HOST_COMPONENT/TARGET`: Run target `TARGET` of
the Makefile of `HOST_COMPONENT`.

`output/target/TARGET_COMPONENT`: Run target `TARGET` of the Makefile of
`TARGET_COMPONENT`.

## Tips
For cross-compilation, build the toolchain for the building environment at
first, and then build the toolchain for the hosting environment with `HOST` and
`VITASDK_HOST` variables.

For building on MSYS2 or MinGW-w64, specify `"CMAKE_FLAGS=-G 'MSYS Makefiles'"`.
It should NOT be `MinGW Makefiles` because the Makefiles will be called from
the buildscript, which uses the shell. You should also set `HOST` if you
specify `BUILD_DEPENDENCY` because `configure` of libelf cannot guess the host.
