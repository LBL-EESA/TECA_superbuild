# TECA Superbuild
The TECA superbuild contains build scripts for [TECA](https://github.com/LBL-EESA/TECA)
and all of its 3rd-party dependencies. This project provides an easy way to get all
of TECA's dependencies and insure that NetCDF and HDF5 are built thread-safe.

## Quick Start
To build the latest released version of TECA including all of its
dependencies.

```bash
$ git clone --depth=1 https://github.com/LBL-EESA/TECA_superbuild.git
$ cd TECA_superbuild
$ mkdir build
$ cd build
$ cmake -DCMAKE_INSTALL_PREFIX=<prefix> ..
$ make -j <number of build threads> install
```

It's important to set the install prefix to a spot that is
writable as running 'make' installs each dependency as it's
built.

When using clang On OSX one must set the compilers explicitly,
else zlib fails to detect that its being compiled for OSX and
libz will be built as a Linux libarary and will not contain
the correct rpaths, and Python zlib module will fail to import,
as a result breaking setuptools build. One can set the clang
(or other compilers) with

```bash
-DCMAKE_C_COMPILER=`which clang`
-DCMAKE_CXX_COMPILER=`which clang++`
```

When using programs built against this install, source the following
configuration file. This ensures that the install takes precedence
over any conflicting installs that may be present on your system.

```bash
$ source <prefix>/bin/teca_env.sh
```

## Options and Defaults
The following build options are available:

```cmake
MPI4PY_CONFIG "Select the mpi4py configuration" "MPICH"
ENABLE_BOOST "builds and installs Boost" ON
ENABLE_LIBXLSXWRITER "builds and installs libxlsxwriter" ON
ENABLE_MPICH "builds and installs MPICH MPI" ON
WITHOUT_MPI "Disable all dependence on MPI" OFF
ENABLE_NETCDF "builds and installs NetCDF group" ON
ENABLE_PYTHON "builds and installs Python group" ON
ENABLE_MATPLOTLIB "builds and installs mnatplotlib group" ON
ENABLE_UDUNITS "builds and installs UDUNITS" ON
ENABLE_TECA "builds and installs TECA" ON
```
