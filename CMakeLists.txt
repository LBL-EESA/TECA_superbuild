cmake_minimum_required(VERSION 3.0)

project(TECA_3rdparty)
include(ExternalProject)

# this web server serves up the tarballs
set(TECA_DEPS_URL "http://missmarple.lbl.gov/TECA/TECA_deps"
    CACHE STRING "URL to a web server where the dependency tarballs live")

# The following versions of each library are installed by this script:
set(MPI_SOURCE mpich-3.2)
set(ZLIB_SOURCE zlib-1.2.8)
set(HDF5_SOURCE hdf5-1.8.17)
set(NETCDF_SOURCE netcdf-4.4.1)
set(UDUNITS_SOURCE udunits-2.2.20)
set(BOOST_SOURCE boost_1_61_0)
set(NCURSES_SOURCE ncurses-6.0)
set(READLINE_SOURCE readline-6.3)
set(PYTHON_SOURCE Python-2.7.12)
set(SETUPTOOLS_SOURCE setuptools-25.1.0)
set(SWIG_SOURCE swig-3.0.10)
set(CYTHON_SOURCE Cython-0.24.1)
set(NUMPY_SOURCE numpy-1.11.1)
set(MPI4PY_SOURCE mpi4py-2.0.0)
set(FREETYPE_SOURCE freetype-2.6)
set(LIBPNG_SOURCE libpng-1.6.23)
set(MATPLOTLIB_SOURCE matplotlib-2.0.0b3)

# enable/disable each piece, all on by default
option(ENABLE_BOOST "Install Boost" ON)
option(ENABLE_LIBXLSXWRITER "Install libxlsxwriter" ON)
option(ENABLE_MPI "Install MPI group" ON)
option(ENABLE_NETCDF "Install NetCDF group" ON)
option(ENABLE_PYTHON "Install Python group" ON)
option(ENABLE_TECA "Install TECA" ON)
option(ENABLE_UDUNITS "Install UDUNITS" ON)

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
elseif(TARGET_PLATFORM STREQUAL "native")
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS_RELEASE "-O3 -march=native -mtune=native -mavx -DNDEBUG"
        CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=native -mtune=native -mavx -DNDEBUG"
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
set(c_flags)
set(cxx_flags)
if (CMAKE_BUILD_TYPE STREQUAL "Release")
  set(c_flags ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_RELEASE})
  set(cxx_flags ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE})
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(c_flags ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_DEBUG})
  set(cxx_flags ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG})
else()
  message(FATAL_ERROR "Unknown build type: ${CMAKE_BUILD_TYPE}")
endif()
message(STATUS "Compiling with CFLAGS=${c_flags}")
message(STATUS "Compiling with CXXFLAGS=${cxx_flags}")

# set the build enviornment for autotools builds and Python builds
# this ensures that python-config works as expected and prevents
# external Python installs from mixing in. this is also the environment
# that should be used at run-time.
set(env CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} "CFLAGS=${c_flags}" "CXXFLAGS=${cxx_flags}"
    LD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib/:${CMAKE_INSTALL_PREFIX}/lib64/:$ENV{LD_LIBRARY_PATH}
    DYLD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib/:${CMAKE_INSTALL_PREFIX}/lib64/:$ENV{DYLD_LIBRARY_PATH}
    PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:${CMAKE_INSTALL_PREFIX}/lib64/pkgconfig:$ENV{PKG_CONFIG_PATH}
    PYTHONPATH=${CMAKE_INSTALL_PREFIX}/lib/python2.7/site-packages/
    PATH=${CMAKE_INSTALL_PREFIX}/bin/:$ENV{PATH})

# configure a bash script that will let us reproduce
# the build enviornment at run-time
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/teca_env.sh.in
    ${CMAKE_CURRENT_BINARY_DIR}/teca_env.sh @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/teca_env.sh
    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# Build MPICH if MPI is requested.
if (ENABLE_MPI)
    message(STATUS "MPI -- enabled")
    ExternalProject_Add(mpich
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${MPI_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPI_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${MPI_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --disable-maintainer-mode --enable-threads=multiple
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "MPI -- disabled")
endif()

# zlib
if (ENABLE_PYTHON OR ENABLE_NETCDF)
    message(STATUS "zlib -- enabled")
    ExternalProject_Add(zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${ZLIB_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "zlib -- disabled")
endif()

# NetCDF group
if (ENABLE_NETCDF)
    # Build the HDF5 parallel I/O library.
    message(STATUS "HDF5 -- enabled")
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
    message(STATUS "NetCDF -- enabled")
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
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "HDF5 -- disabled")
    message(STATUS "NetCDF -- disabled")
endif()

# Build UDUnits.
if (ENABLE_UDUNITS)
    message(STATUS "UDUNITS -- enabled")

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
    message(STATUS "UDUNITS -- disabled")
endif()

# Build Boost.
if (ENABLE_BOOST)
    message(STATUS "Boost -- enabled")

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
    message(STATUS "Boost -- disabled")
endif()

# Python group
if (ENABLE_PYTHON)
    # ncurses
    message(STATUS "ncurses -- enabled")
    ExternalProject_Add(ncurses
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NCURSES_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # readline
    message(STATUS "readline -- enabled")
    ExternalProject_Add(readline
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${READLINE_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Python.
    message(STATUS "Python -- enabled")
    ExternalProject_Add(Python
        DEPENDS ncurses readline
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${PYTHON_SOURCE}.tgz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}/configure
          --enable-shared --prefix=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build setuptools
    message(STATUS "setuptools -- enabled")
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
    message(STATUS "SWIG -- enabled")
    ExternalProject_Add(SWIG
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${SWIG_SOURCE}.tar.gz
        DEPENDS Python
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}/configure
            --with-python=${CMAKE_INSTALL_PREFIX}/bin/python --prefix=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Cython.
    message(STATUS "Cython -- enabled")
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
    message(STATUS "NumPy -- enabled")
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
    if (ENABLE_MPI)
        message(STATUS "mpi4py -- enabled")
        ExternalProject_Add(mpi4py
            DEPENDS mpich numpy
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${MPI4PY_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPI4PY_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build
                --mpicc=${CMAKE_INSTALL_PREFIX}/bin/mpicc
            INSTALL_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python setup.py
            install --prefix=${CMAKE_INSTALL_PREFIX}
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1 LOG_INSTALL 1)
    endif()

    # libpng
    message(STATUS "libpng -- enabled")
    ExternalProject_Add(libpng
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${LIBPNG_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${LIBPNG_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${LIBPNG_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # freetype
    message(STATUS "freetype -- enabled")
    ExternalProject_Add(freetype
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${FREETYPE_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${FREETYPE_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${FREETYPE_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build matplotlib
    message(STATUS "matplotlib -- enabled")
    ExternalProject_Add(matplotlib
        DEPENDS Python numpy freetype libpng
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${MATPLOTLIB_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${MATPLOTLIB_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
            setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
else()
    message(STATUS "Python -- disabled")
    message(STATUS "setuptools -- disabled")
    message(STATUS "SWIG -- disabled")
    message(STATUS "Cython -- disabled")
    message(STATUS "NumPy -- disabled")
    if (ENABLE_MPI)
        message(STATUS "mpi4py -- disabled")
    endif()
    message(STATUS "libpng -- disabled")
    message(STATUS "freetype -- disabled")
    message(STATUS "matplotlib -- disabled")
endif()

# Build libxlsxwriter.
if (ENABLE_LIBXLSXWRITER)
    message(STATUS "LIBXLSXWRITER -- enabled")
    # First copy the source files to a new location.
    execute_process(COMMAND cmake -E copy_directory ${PROJECT_SOURCE_DIR}/libxlsxwriter
        ${PROJECT_BINARY_DIR}/libxlsxwriter RESULT_VARIABLE stat)

    # Now tweak the Makefile to install files in the right spot.
    file(READ ${PROJECT_SOURCE_DIR}/libxlsxwriter/Makefile xlsx_makefile)
    string(REPLACE "install:" "install: all" xlsx_makefile ${xlsx_makefile})
    string(REPLACE "cp -r include/* /usr/include" "cp -R include/* ${CMAKE_INSTALL_PREFIX}/include"
        xlsx_makefile ${xlsx_makefile})
    string(REPLACE "cp lib/* /usr/lib" "cp lib/* ${CMAKE_INSTALL_PREFIX}/lib"
        xlsx_makefile ${xlsx_makefile})
    file(WRITE ${PROJECT_BINARY_DIR}/libxlsxwriter/Makefile ${xlsx_makefile})

    # Finally, build the thing.
    ExternalProject_Add(libxlsxwriter
        DEPENDS udunits # For creating directories in prefix.
        SOURCE_DIR ${PROJECT_BINARY_DIR}/libxlsxwriter
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} make install
        BINARY_DIR ${PROJECT_BINARY_DIR}/libxlsxwriter
        INSTALL_COMMAND ""
        LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "LIBXLSXWRITER -- enabled")
endif()

# TECA proper
if (ENABLE_TECA)
    message(STATUS "TECA -- enabled")
    set(teca_deps netcdf Python boost libxlsxwriter udunits)
    if (ENABLE_MPI)
        list(APPEND teca_deps mpi4py)
    endif()
    ExternalProject_Add(TECA
        DEPENDS ${teca_deps}
        SOURCE_DIR ${PROJECT_SOURCE_DIR}/TECA
        CMAKE_COMMAND env ${env} ${CMAKE_COMMAND} ../TECA
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            -DTECA_HAS_VTK=OFF
        LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "TECA -- disabled")
endif()
