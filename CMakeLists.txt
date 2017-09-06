cmake_minimum_required(VERSION 3.0)

project(TECA_3rdparty)
include(ExternalProject)

# where various resources are housed and served
set(TECA_URL "http://github.com/LBL-EESA/TECA"
    CACHE STRING "URL to the TECA source code repository")

set(TECA_DATA_URL "svn://missmarple.lbl.gov/work3/teca/TECA_data"
    CACHE STRING "URL to the TECA regresion test data repository")

set(TECA_DEPS_URL "http://missmarple.lbl.gov/TECA/TECA_deps"
    CACHE STRING "URL to the dependency tarballs")

set(LIBXLSXWRITER_URL http://github.com/burlen/libxlsxwriter.git)

# The following versions of each library are installed by this script:
set(MPICH_SOURCE mpich-3.2)
set(OPENMPI_SOURCE openmpi-2.0.1)
set(OPENSSL_SOURCE openssl-1.1.0f)
set(ZLIB_SOURCE zlib-1.2.8)
set(HDF5_SOURCE hdf5-1.8.17)
set(NETCDF_SOURCE netcdf-4.4.1)
set(UDUNITS_SOURCE udunits-2.2.20)
set(BOOST_SOURCE boost_1_64_0)
set(NCURSES_SOURCE ncurses-6.0)
set(READLINE_SOURCE readline-6.3)
set(PYTHON_SOURCE Python-2.7.13)
set(SETUPTOOLS_SOURCE setuptools-25.1.0)
set(SWIG_SOURCE swig-3.0.10)
set(CYTHON_SOURCE Cython-0.24.1)
set(NUMPY_SOURCE numpy-1.11.2)
set(MPI4PY_SOURCE mpi4py-2.0.0)
set(FREETYPE_SOURCE freetype-2.6)
set(LIBPNG_SOURCE libpng-1.6.23)
set(SIX_SOURCE six-1.10.0)
set(PYTHON_DATEUTIL_SOURCE python-dateutil-2.5.3)
set(PYPARSING_SOURCE pyparsing-2.1.9)
set(CYCLER_SOURCE cycler-0.10.0)
set(PYTZ_SOURCE pytz-2016.6.1)
set(SUBPROCESS32_SOURCE subprocess32-3.2.7)
set(FUNCTOOLS32_SOURCE functools32-3.2.3-2)
set(MATPLOTLIB_SOURCE matplotlib-2.0.0b3)
set(LIBXLSXWRITER_SOURCE cmake_configure)
set(TECA_SOURCE 2.1.1 CACHE STRING
    "branch to checkout from the TECA git repository")

# enable/disable each piece, all on by default
option(ENABLE_BOOST "builds and installs Boost" ON)
option(ENABLE_LIBXLSXWRITER "builds and installs libxlsxwriter" ON)
option(ENABLE_MPICH "builds and installs MPICH MPI" OFF)
option(ENABLE_OPENMPI "builds and installs OpenMPI MPI" ON)
option(ENABLE_CRAY_MPICH "Auto detect MPICH configuration for Cray systems" OFF)
option(WITHOUT_MPI "Disable all dependence on MPI" OFF)
option(ENABLE_NETCDF "builds and installs NetCDF group" ON)
option(ENABLE_PYTHON "builds and installs Python group" ON)
option(ENABLE_MATPLOTLIB "builds and installs matplotlib group" ON)
option(ENABLE_TECA "builds and installs TECA" ON)
option(ENABLE_TECA_TEST "runs the TECA regression tests" ON)
option(ENABLE_TECA_DATA "downloads the TECA test datasets" ON)
option(ENABLE_UDUNITS "builds and installs UDUNITS" ON)
option(ENABLE_OPENSSL "builds and installs OpenSSL" ON)
option(ENABLE_MEMCHECK "configures for use with valgrind" OFF)

# the list of enabled dependencies
set(teca_deps)

message(STATUS "C compiler is ${CMAKE_C_COMPILER} (${CMAKE_C_COMPILER_ID})")
message(STATUS "C++ compiler is ${CMAKE_CXX_COMPILER} (${CMAKE_CXX_COMPILER_ID})")

# We need to override the default value of CMAKE_INSTALL_PREFIX.
if (CMAKE_INSTALL_PREFIX STREQUAL "/usr/local")
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR} CACHE PATH "" FORCE)
endif()
message(STATUS "Installing libraries in ${CMAKE_INSTALL_PREFIX}")

# if we forgot to set the build type default to release
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release"
      CACHE STRING "options are: Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()
message(STATUS "Configuring a ${CMAKE_BUILD_TYPE} build")

# Sniff out the platform option and set compiler flags.
# default to native, which gives the best performance
# but is not portable. use generic for max protability.
# sandybridge should be very portible, covering processors
# released 2011 or later.
set (TARGET_PLATFORM "native" CACHE STRING
    "Select from a set of pre-defined compiler flags")
set_property(CACHE TARGET_PLATFORM PROPERTY STRINGS
    "generic" "native" "sandybridge")

if (TARGET_PLATFORM STREQUAL "generic")
  # go with the defaults specified by the build type
elseif(TARGET_PLATFORM STREQUAL "knl")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_C_FLAGS_RELEASE "-O3 -march=knl -mtune=knl -DNDEBUG"
            CACHE STRING "" FORCE)
        set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=knl -mtune=knl -DNDEBUG"
            CACHE STRING "" FORCE)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        message(SEND_ERROR "No knl support with clang")
    endif()
elseif(TARGET_PLATFORM STREQUAL "native")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_C_FLAGS_RELEASE "-O3 -march=native -mtune=native -DNDEBUG"
            CACHE STRING "" FORCE)
        set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=native -mtune=native -DNDEBUG"
            CACHE STRING "" FORCE)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # Clang's offerings are pretty spare at the moment (maybe?).
        # go with the defaults
    endif()
elseif(TARGET_PLATFORM STREQUAL "sandybridge")
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS_RELEASE "-O3 -march=sandybridge -mtune=sandybridge -mavx -DNDEBUG"
        CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=sandybridge -mtune=sandybridge -mavx -DNDEBUG"
        CACHE STRING "" FORCE)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Clang's offerings are pretty spare at the moment (maybe?).
    # go with the defaults
  endif()
else()
    message(FATAL_ERROR "Unknown platform: ${TARGET_PLATFORM}")
endif()
message(STATUS "Configuring for ${TARGET_PLATFORM} platform")

# collect flags to pass them into autotools scripts
set(cpp_flags "$ENV{CPPFLAGS} -I${CMAKE_INSTALL_PREFIX}/include")
if (ENABLE_MEMCHECK)
    string(CONCAT cpp_flags "${cpp_flags} -DPy_USING_MEMORY_DEBUGGER")
endif()
message(STATUS "CPPFLAGS=${cpp_flags}")

set(c_flags "-I${CMAKE_INSTALL_PREFIX}/include")
set(cxx_flags "-I${CMAKE_INSTALL_PREFIX}/include")
if (CMAKE_BUILD_TYPE STREQUAL "Release")
    string(CONCAT c_flags "${c_flags} ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_RELEASE}")
    string(CONCAT cxx_flags "${cxx_flags} ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}")
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(CONCAT c_flags "${c_flags} ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_DEBUG}")
    string(CONCAT cxx_flags "${cxx_flags} ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG}")
else()
    message(FATAL_ERROR "Unknown build type: ${CMAKE_BUILD_TYPE}")
endif()
message(STATUS "CFLAGS=${c_flags}")
message(STATUS "CXXFLAGS=${cxx_flags}")

set(ld_flags "-L/${CMAKE_INSTALL_PREFIX}/lib -L${CMAKE_INSTALL_PREFIX}/lib64")
message(STATUS "LDFLAGS=${ld_flags}")

# collect MPI falgs passed on the command line, usually only for
# Cray builds
set(mpi_flags)
if (NOT WITHOUT_MPI AND NOT ENABLE_MPICH AND NOT ENABLE_OPENMPI)
    if (ENABLE_CRAY_MPICH)
        # Cray does not follow usual conventions of mpicc, mpicxx, mpif90 etc
        set(MPI_C_COMPILER ${CMAKE_C_COMPILER} CACHE STRING "C compiler for MPI programs")
        set(MPI_CXX_COMPILER ${CMAKE_CXX_COMPILER} CACHE STRING "C++ compiler for MPI programs")
        # use pkg-config to detect MPI dependencies
        find_package(PkgConfig QUIET)
        pkg_check_modules(CRAY_MPICH REQUIRED QUIET mpich)
        # set variables needed by CMake FindMPI
        set(MPI_INCLUDE_PATH ${CRAY_MPICH_INCLUDE_DIRS} CACHE STRING "MPI include directories")
        set(MPI_C_LIBRARIES ${CRAY_MPICH_LDFLAGS} CACHE STRING "MPI link dependencies")
        set(MPI_CXX_LIBRARIES "" CACHE STRING "MPI C++ dependencies (empty)")
    endif()
    list(APPEND mpi_flags "-DMPI_CXX_COMPILER=${MPI_CXX_COMPILER}")
    list(APPEND mpi_flags "-DMPI_C_COMPILER=${MPI_C_COMPILER}")
    list(APPEND mpi_flags "-DMPI_CXX_LIBRARIES=")
    string(REPLACE ";" " " tmp "${MPI_C_LIBRARIES}")
    list(APPEND mpi_flags "-DMPI_C_LIBRARIES=${tmp}")
    list(APPEND mpi_flags "-DMPI_INCLUDE_PATH=${MPI_INCLUDE_PATH}")
    list(APPEND mpi_flags "-DMPI_EXTRA_LIBRARY=")
    list(APPEND mpi_flags "-DMPIEXEC=${MPIEXEC}")
endif()
set(MPI_FLAGS ${mpi_flags} CACHE STRING "MPI configuration overides")
message(STATUS "MPI_FLAGS=${MPI_FLAGS}")

# flags for testing
set(CTEST_FLAGS  --output-on-failure CACHE STRING
    "flags passed to ctest during tests after install")

# set the build enviornment for autotools builds and Python builds
# this ensures that python-config works as expected and prevents
# external Python installs from mixing in. this is also the environment
# that should be used at run-time.
set(py_env)
if (ENABLE_PYTHON)
    set(py_env PYTHONHOME=${CMAKE_INSTALL_PREFIX} MPLBACKEND=Agg
        PYTHONPATH=${CMAKE_INSTALL_PREFIX}/lib:${CMAKE_INSTALL_PREFIX}/lib/python2.7/site-packages/)
endif()
set(env CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER}
    "CPPFLAGS=${cpp_flags}" "CFLAGS=${c_flags}" "CXXFLAGS=${cxx_flags}" "LDFLAGS=${ld_flags}"
    LD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib/:${CMAKE_INSTALL_PREFIX}/lib64/:$ENV{LD_LIBRARY_PATH}
    DYLD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib/:${CMAKE_INSTALL_PREFIX}/lib64/:$ENV{DYLD_LIBRARY_PATH}
    PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:${CMAKE_INSTALL_PREFIX}/lib64/pkgconfig:$ENV{PKG_CONFIG_PATH}
    PATH=.:${CMAKE_INSTALL_PREFIX}/bin/:$ENV{PATH} ${py_env})

# configure a bash script that will let us reproduce
# the build enviornment at run-time
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/teca_env.sh.in
    ${CMAKE_CURRENT_BINARY_DIR}/teca_env.sh @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/teca_env.sh
    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# Build MPICH if MPI is requested.
if (NOT WITHOUT_MPI AND ENABLE_CRAY_MPICH)
    message(STATUS "MPICH .................. Disabled")
    message(STATUS "Cray MPICH ............. Enabled")
    message(STATUS "OpenMPI ................ Disabled")
elseif (NOT WITHOUT_MPI AND ENABLE_MPICH)
    message(STATUS "MPICH .................. Enabled")
    message(STATUS "Cray MPICH ............. Disabled")
    message(STATUS "OpenMPI ................ Disabled")
    ExternalProject_Add(mpi
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${MPICH_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPICH_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${MPICH_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --disable-maintainer-mode --enable-threads=multiple
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
elseif (NOT WITHOUT_MPI AND ENABLE_OPENMPI)
    message(STATUS "MPICH .................. Disabled")
    message(STATUS "Cray MPICH ............. Disabled")
    message(STATUS "OpenMPI ................ Enabled")
    ExternalProject_Add(mpi
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${OPENMPI_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${OPENMPI_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${OPENMPI_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --enable-mpi-thread-multiple
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "MPICH .................. Disabled")
    message(STATUS "Cray MPICH ............. Disabled")
    message(STATUS "OpenMPI ................ Disabled")
endif()

# zlib
if (ENABLE_PYTHON OR ENABLE_NETCDF OR ENABLE_LIBXLSXWRITER OR ENABLE_OPENSSL)
    message(STATUS "zlib ................... Enabled")
    ExternalProject_Add(zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${ZLIB_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}
        CONFIGURE_COMMAND env ${env}
             ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "zlib ................... Disabled")
endif()

# OpenSSL
if (ENABLE_OPENSSL)
    message(STATUS "OpenSSL ................ Enabled")
    list(APPEND teca_deps openssl)
    ExternalProject_Add(openssl
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${OPENSSL_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${OPENSSL_SOURCE}
        CONFIGURE_COMMAND env ${env}
             ${PROJECT_BINARY_DIR}/${OPENSSL_SOURCE}/config
            --prefix=${CMAKE_INSTALL_PREFIX} ${c_flags}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "OpenSSL ................ Disabled")
endif()

# NetCDF group
if (ENABLE_NETCDF)
    # Build the HDF5 parallel I/O library.
    message(STATUS "HDF5 ................... Enabled")
    set(hdf5_deps zlib)
    set(HDF5_CONFIG_FLAGS --enable-unsupported  --enable-hl
        --enable-threadsafe --enable-production)
    # unfortunately hdf5's configure script provides no way to set path
    # to mpi libraries. for now we'll disable parallel hdf5
    #if (NOT WITHOUT_MPI)
    #    if (ENABLE_MPICH)
    #       list(APPEND hdf5_deps mpich)
    #    endif()
    #    list(APPEND HDF5_CONFIG_FLAGS --enable-parallel)
    #endif()
    ExternalProject_Add(hdf5
        DEPENDS ${hdf5_deps}
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${HDF5_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${HDF5_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${HDF5_SOURCE}/configure
          --prefix=${CMAKE_INSTALL_PREFIX} ${HDF5_CONFIG_FLAGS}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build NetCDF.
    message(STATUS "NetCDF ................. Enabled")
    list(APPEND teca_deps netcdf)
    ExternalProject_Add(netcdf
        DEPENDS hdf5
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NETCDF_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NETCDF_SOURCE}
        CMAKE_COMMAND ${CMAKE_COMMAND} ../${NETCDF_SOURCE}
           -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
           "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
           "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS}"
           "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS}"
           -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
           "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
           "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
           "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
           -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
           -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
           -DENABLE_NETCDF4=ON -DENABLE_TESTS=OFF -DBUILD_EXAMPLES=OFF
           -DNC_HAVE_PARALLEL_HDF5=OFF -DHDF5_IS_PARALLEL=OFF
           -DHDF5_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "HDF5 ................... Disabled")
    message(STATUS "NetCDF ................. Disabled")
endif()

# Build UDUnits.
if (ENABLE_UDUNITS)
    message(STATUS "UDUNITS ................ Enabled")
    list(APPEND teca_deps udunits)
    ExternalProject_Add(udunits
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${UDUNITS_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${UDUNITS_SOURCE}
        CMAKE_COMMAND ${CMAKE_COMMAND} ../${UDUNITS_SOURCE}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}"
            "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "UDUNITS ................ Disabled")
endif()

# Build Boost.
if (ENABLE_BOOST)
    message(STATUS "Boost .................. Enabled")
    list(APPEND teca_deps boost)
    if (APPLE AND ((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") OR
        (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")))
        set(boost_toolset toolset=clang)
        set(boost_cxx_flags -stdlib=libc++)
        set(boost_ld_flags linkflags=-stdlib=libc++)
    endif()
    ExternalProject_Add(boost
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${BOOST_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${BOOST_SOURCE}
        CONFIGURE_COMMAND env ${env}
            ./bootstrap.sh --prefix=${CMAKE_INSTALL_PREFIX}
            -with-libraries=program_options
        BUILD_COMMAND ./b2 ${boost_toolset}
            "cxxflags=${cxx_flags} -std=c++11 ${boost_cxx_flags}" "${boost_ld_flags}"
        INSTALL_COMMAND ./b2 install --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "Boost .................. Disabled")
endif()

# Python group
if (ENABLE_PYTHON)
    # ncurses
    message(STATUS "ncurses ................ Enabled")
    ExternalProject_Add(ncurses
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NCURSES_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # readline
    message(STATUS "readline ............... Enabled")
    ExternalProject_Add(readline
        DEPENDS ncurses
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${READLINE_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Python.
    message(STATUS "Python ................. Enabled")
    ExternalProject_Add(Python
        DEPENDS ncurses readline zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${PYTHON_SOURCE}.tgz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}/configure
          --enable-shared --prefix=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build setuptools
    message(STATUS "setuptools ............. Enabled")
    ExternalProject_Add(setuptools
        DEPENDS Python
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${SETUPTOOLS_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${SETUPTOOLS_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
            setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

    # Build Swig.
    message(STATUS "SWIG ................... Enabled")
    list(APPEND teca_deps SWIG)
    ExternalProject_Add(SWIG
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${SWIG_SOURCE}.tar.gz
        DEPENDS Python
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}/configure
            --with-python=${CMAKE_INSTALL_PREFIX}/bin/python --prefix=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Cython.
    message(STATUS "Cython ................. Enabled")
    ExternalProject_Add(Cython
        DEPENDS Python
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${CYTHON_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${CYTHON_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
            setup.py build install --prefix=${CMAKE_INSTALL_PREFIX}
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

    # Build numpy.
    message(STATUS "NumPy .................. Enabled")
    list(APPEND teca_deps numpy)
    ExternalProject_Add(numpy
        DEPENDS Python Cython setuptools
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NUMPY_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NUMPY_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
            setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

    # Build mpi4py if MPI was requested.
    set(MPI4PY_CONFIG "MPICH" CACHE STRING
        "Select the mpi4py configuration we use.")

    if (NOT WITHOUT_MPI)
        set(mpi4py_deps numpy)
        if (ENABLE_MPICH OR ENABLE_OPENMPI)
            list(APPEND mpi4py_deps mpi)
        endif()
        if (ENABLE_CRAY_MPICH)
            # set variables needed by mpi4py
            string(REPLACE ";" " " MPI4PY_LDFLAGS "${CRAY_MPICH_LDFLAGS}")
            string(REPLACE ";" " " MPI4PY_CFLAGS "${CRAY_MPICH_CFLAGS}")
        endif()
        configure_file(mpi4py.cfg.in mpi4py.cfg)
        message(STATUS "mpi4py ................. Enabled")
        list(APPEND teca_deps mpi4py)
        ExternalProject_Add(mpi4py
            DEPENDS ${mpi4py_deps}
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${MPI4PY_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPI4PY_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build
                --mpi=${MPI4PY_CONFIG},${PROJECT_BINARY_DIR}/mpi4py.cfg
            INSTALL_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python setup.py
            install --prefix=${CMAKE_INSTALL_PREFIX}
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1 LOG_INSTALL 1)
    else()
        message(STATUS "mpi4py ................. Disabled")
    endif()

    if (ENABLE_MATPLOTLIB)
        find_program(PKG_CONFIG pkg-config DOC "pkg-config program")
        if (NOT PKG_CONFIG)
            message(FATAL_ERROR "pkg-config is required to build matplotlib")
        endif()

        # libpng
        set(system_libpng OFF)
        if (APPLE)
            # see issue #20
            find_library(have_system_libpng libpng.dylib)
            if (have_system_libpng)
                set(system_libpng ON)
                message(STATUS "libpng ................. System")
            endif()
        endif()
        if (NOT system_libpng)
            message(STATUS "libpng ................. Enabled")
            ExternalProject_Add(libpng
                DEPENDS zlib
                DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
                URL ${TECA_DEPS_URL}/${LIBPNG_SOURCE}.tar.gz
                SOURCE_DIR ${PROJECT_BINARY_DIR}/${LIBPNG_SOURCE}
                CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${LIBPNG_SOURCE}/configure
                    --prefix=${CMAKE_INSTALL_PREFIX}
                BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
        endif()

        # freetype
        message(STATUS "freetype ............... Enabled")
        ExternalProject_Add(freetype
            DEPENDS zlib
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${FREETYPE_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${FREETYPE_SOURCE}
            CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${FREETYPE_SOURCE}/configure
                --prefix=${CMAKE_INSTALL_PREFIX}
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # six
        message(STATUS "six .................... Enabled")
        ExternalProject_Add(six
            DEPENDS setuptools
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${SIX_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${SIX_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # python_dateutil
        message(STATUS "python_dateutil ........ Enabled")
        ExternalProject_Add(python_dateutil
            DEPENDS six
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${PYTHON_DATEUTIL_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYTHON_DATEUTIL_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # pyparsing
        message(STATUS "pyparsing .............. Enabled")
        ExternalProject_Add(pyparsing
            DEPENDS setuptools
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${PYPARSING_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYPARSING_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # cycler
        message(STATUS "cycler ................. Enabled")
        ExternalProject_Add(cycler
            DEPENDS six
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${CYCLER_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${CYCLER_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # pytz
        message(STATUS "pytz ................... Enabled")
        ExternalProject_Add(pytz
            DEPENDS setuptools
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${PYTZ_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYTZ_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # subprocess32
        message(STATUS "subprocess32 ........... Enabled")
        ExternalProject_Add(subprocess32
            DEPENDS setuptools
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${SUBPROCESS32_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${SUBPROCESS32_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # functools32
        message(STATUS "functools32 ............ Enabled")
        ExternalProject_Add(functools32
            DEPENDS setuptools
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${FUNCTOOLS32_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${FUNCTOOLS32_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

        # Build matplotlib
        message(STATUS "matplotlib ............. Enabled")
        list(APPEND teca_deps matplotlib)
        set(matplotlib_deps numpy freetype pyparsing python_dateutil
            cycler pytz subprocess32 functools32)
        if (NOT system_libpng)
            list(APPEND matplotlib_deps libpng)
        endif()
        ExternalProject_Add(matplotlib
            DEPENDS Python numpy ${matplotlib_deps}
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${MATPLOTLIB_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${MATPLOTLIB_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
        else()
            message(STATUS "libpng ................. Disabled")
            message(STATUS "freetype ............... Disabled")
            message(STATUS "six .................... Disabled")
            message(STATUS "python_dateutil ........ Disabled")
            message(STATUS "pyparsing .............. Disabled")
            message(STATUS "cycler ................. Disabled")
            message(STATUS "pytz ................... Disabled")
            message(STATUS "subprocess32 ........... Disabled")
            message(STATUS "matplotlib ............. Disabled")
        endif()
else()
    message(STATUS "Python ................. Disabled")
    message(STATUS "setuptools ............. Disabled")
    message(STATUS "SWIG ................... Disabled")
    message(STATUS "Cython ................. Disabled")
    message(STATUS "NumPy .................. Disabled")
    message(STATUS "mpi4py ................. Disabled")
    message(STATUS "libpng ................. Disabled")
    message(STATUS "freetype ............... Disabled")
    message(STATUS "six .................... Disabled")
    message(STATUS "python_dateutil ........ Disabled")
    message(STATUS "pyparsing .............. Disabled")
    message(STATUS "cycler ................. Disabled")
    message(STATUS "pytz ................... Disabled")
    message(STATUS "subprocess32 ........... Disabled")
    message(STATUS "functools32 ............ Disabled")
    message(STATUS "matplotlib ............. Disabled")
endif()

# Build libxlsxwriter.
if (ENABLE_LIBXLSXWRITER)
    message(STATUS "LIBXLSXWRITER .......... Enabled")
    list(APPEND teca_deps libxlsxwriter zlib)
    ExternalProject_Add(libxlsxwriter
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        #URL ${TECA_DEPS_URL}/${LIBXLSXWRITER_SOURCE}.tar.gz
        GIT_REPOSITORY ${LIBXLSXWRITER_URL}
        GIT_TAG cmake_configure
        UPDATE_COMMAND ""
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${LIBXLSXWRITER_SOURCE}
        CMAKE_COMMAND env ${env} ${CMAKE_COMMAND}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "LIBXLSXWRITER .......... Disabled")
endif()

# TECA proper
if (ENABLE_TECA)
    message(STATUS "TECA ................... Enabled")
    # download the regression test data
    set(TECA_DATA_REV "-rHEAD")
    set(TECA_DATA_UPDATE svn update)
    set(TECA_UPDATE git pull --rebase)
    if (TECA_SOURCE STREQUAL "2.0.0")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r24")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "2.1.0" OR TECA_SOURCE STREQUAL "2.1.1")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r34")
        set(TECA_DATA_UPDATE "")
    endif()
    set(tmp)
    if (ENABLE_TECA_DATA)
        message(STATUS "TECA data .............. Enabled")
        ExternalProject_Add(TECA_data
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            SVN_REPOSITORY ${TECA_DATA_URL}
            SVN_REVISION ${TECA_DATA_REV}
            UPDATE_COMMAND ${TECA_DATA_UPDATE}
            CONFIGURE_COMMAND "" BUILD_COMMAND ""
            INSTALL_COMMAND "" LOG_DOWNLOAD 1)
        set(tmp ${PROJECT_BINARY_DIR}/TECA_data-prefix/src/TECA_data)
    else()
        message(STATUS "TECA data .............. Disabled")
    endif()
    set(TECA_DATA_ROOT ${tmp} CACHE PATH "Path to TECA regression test data")
    if (ENABLE_TECA_TEST)
        message(STATUS "TECA test .............. Enabled")
    else()
        message(STATUS "TECA test .............. Disabled")
    endif()
    # download and build TECA
    ExternalProject_Add(TECA
        DEPENDS ${teca_deps}
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        GIT_REPOSITORY ${TECA_URL}
        GIT_TAG ${TECA_SOURCE}
        UPDATE_COMMAND ${TECA_UPDATE}
        CMAKE_COMMAND env ${env} ${CMAKE_COMMAND}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            ${MPI_FLAGS} -DTECA_HAS_VTK=OFF
            -DTECA_DATA_ROOT=${TECA_DATA_ROOT}
            -DBUILD_TESTING=${ENABLE_TECA_TEST}
            ${PROJECT_BINARY_DIR}/TECA
        TEST_AFTER_INSTALL ${ENABLE_TECA_TEST}
        TEST_COMMAND env ${env} ctest ${CTEST_FLAGS} || true
        LOG_DOWNLOAD 1 LOG_CONFIGURE 0 LOG_BUILD 0 LOG_INSTALL 0)
else()
    message(STATUS "TECA ................... Disabled")
    message(STATUS "TECA data .............. Disabled")
    message(STATUS "TECA test .............. Disabled")
endif()
