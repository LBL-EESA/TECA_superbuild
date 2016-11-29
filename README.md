# TECA Superbuild
The TECA superbuild contains build scripts for [TECA](https://github.com/LBL-EESA/TECA)  and all of its 3rd-party dependencies.

## Quick Start
To build the released version of TECA including all of its
dependencies.

```bash
$ mkdir build && cd build
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
$ . <prefix>/bin/teca_env.sh
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

## For Developers
This project provides an easy way to get all of the dependencies
and insure that HDF5 is built trhead-safe. It is recommended to
use a separate TECA clone and disable the TECA build here.

```bash
-DENABLE_TECA=OFF
```

When rebuilding the superbuild after modification it's recommended
to remove the install, as the old installed files can cause problems
particularly with Python.

```bash
$ cd build
$ rm -rf * # clean the previous build
$ rm -rf <prefix> # clean the previous install
$ cmake -DCMAKE_INSTALL_PREFIX=<prefix> ..
$ make -j <number of build threads> install
```
