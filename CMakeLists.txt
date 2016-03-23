cmake_minimum_required(VERSION 3.0)

project(TECA_3rdparty)
include(ExternalProject)

# The following versions of each library are installed by this script:
# MPICH:         3.2
# HDF5:          1.8.16
# NetCDF:        4.4.0
# UDUnits:       2.2.20
# Python:        2.7.11
# Cython:        0.23.4
# Numpy:         1.10.4
# Mpi4py:        2.0.0
# Boost:         1_60_0
# Libxlsxwriter: 0.3.1

option(TECA_HAS_MPI "Build parallel libraries for TECA" ON)

message(STATUS "C compiler is ${CMAKE_C_COMPILER} (${CMAKE_C_COMPILER_ID})")
message(STATUS "C++ compiler is ${CMAKE_CXX_COMPILER} (${CMAKE_CXX_COMPILER_ID})")

# We need to override the default value of CMAKE_INSTALL_PREFIX.
if (CMAKE_INSTALL_PREFIX STREQUAL "/usr/local")
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR} CACHE PATH "" FORCE)
endif()
message(STATUS "Installing libraries in ${CMAKE_INSTALL_PREFIX}...")

# if we forgot to set the build type default to release
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release"
      CACHE STRING "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()
message(STATUS "Configuring a ${CMAKE_BUILD_TYPE} build")

# Sniff out the platform option and set compiler flags.
set (TECA_PLATFORM "generic" CACHE STRING "Select from a set of pre-defined compiler flags")
if (TECA_PLATFORM STREQUAL "generic")
  # go with the defaults specified by the build type
elseif(TECA_PLATFORM STREQUAL "sandybridge")
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_C_FLAGS_RELEASE "-O3 -march=sandybridge -mtune=sandybridge -mavx -DNDEBUG" CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=sandybridge -mtune=sandybridge -mavx -DNDEBUG" CACHE STRING "" FORCE)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Clang's offerings are pretty spare at the moment (maybe?).
    # go with the defaults
  endif()
else()
  message(FATAL_ERROR "Unknown platform: ${TECA_PLATFORM}")
endif()
message(STATUS "Configuring for ${TECA_PLATFORM} platform")

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
if (TECA_HAS_MPI)
  ExternalProject_Add(mpich
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/mpich
                      CONFIGURE_COMMAND env ${ENV} ${PROJECT_SOURCE_DIR}/mpich/configure
                          --prefix=${CMAKE_INSTALL_PREFIX} --disable-maintainer-mode --enable-threads=multiple
                      BUILD_IN_SOURCE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
endif()

# Build the HDF5 parallel I/O library.
ExternalProject_Add(hdf5
                    DEPENDS mpich
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/hdf5
                    CMAKE_COMMAND ${CMAKE_COMMAND} ../hdf5 -Wno-dev
                         -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                         "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
                         "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}"
                         "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}"
                         -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                         "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
                         "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
                         "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
                         -DMPI_C_COMPILER=${CMAKE_INSTALL_PREFIX}/bin/mpicc
                         -DMPI_CXX_COMPILER=${CMAKE_INSTALL_PREFIX}/bin/mpicxx
                         -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                         -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                         -DHDF5_ENABLE_PARALLEL=${TECA_HAS_MPI}
                         -DHDF5_BUILD_CPP_LIB=OFF
                    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

# Build NetCDF.
ExternalProject_Add(netcdf
                    DEPENDS hdf5
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/netcdf
                    CMAKE_COMMAND ${CMAKE_COMMAND} ../netcdf -Wno-dev
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
                         -DNC_HAVE_PARALLEL_HDF5=${TECA_HAS_MPI}
                         -DHDF5_IS_PARALLEL=${TECA_HAS_MPI}
                    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

# Build UDUnits.
ExternalProject_Add(udunits
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/udunits
                    CMAKE_COMMAND ${CMAKE_COMMAND} ../udunits -Wno-dev
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
                    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

# Build Boost.
if (APPLE AND ((CMAKE_CXX_COMPILER_ID STREQUAL "Clang") OR
    (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")))
  set(boost_toolset toolset=clang)
  set(boost_cxx_flags -stdlib=libc++)
  set(boost_ld_flags linkflags=-stdlib=libc++)
endif()
ExternalProject_Add(boost
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/boost
                    CONFIGURE_COMMAND env ${env}
                        ./bootstrap.sh --prefix=${CMAKE_INSTALL_PREFIX}
                        -with-libraries=program_options 
                    BUILD_COMMAND ./b2 ${boost_toolset}
                        "cxxflags=${cxx_flags} -std=c++11 ${boost_cxx_flags}" "${boost_ld_flags}"
                    INSTALL_COMMAND ./b2 install --prefix=${CMAKE_INSTALL_PREFIX}
                    BUILD_IN_SOURCE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

# Build Python.
ExternalProject_Add(Python
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/Python
                    CONFIGURE_COMMAND env ${env} ${PROJECT_SOURCE_DIR}/Python/configure
                        --enable-shared --prefix=${CMAKE_INSTALL_PREFIX}
                    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

# Build Cython.
ExternalProject_Add(Cython
                    DEPENDS Python
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/Cython
                    CONFIGURE_COMMAND ""
                    BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                         setup.py build install --prefix=${CMAKE_INSTALL_PREFIX}
                    INSTALL_COMMAND ""
                    BUILD_IN_SOURCE 1 LOG_BUILD 1)

# Build numpy.
ExternalProject_Add(numpy
                    DEPENDS Cython
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/numpy
                    CONFIGURE_COMMAND ""
                    BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python
                        setup.py build install "--prefix=${CMAKE_INSTALL_PREFIX}"
                    INSTALL_COMMAND ""
                    BUILD_IN_SOURCE 1 LOG_BUILD 1)

# Build mpi4py if requested.
if (TECA_HAS_MPI)
  ExternalProject_Add(mpi4py
                      DEPENDS mpich numpy
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/mpi4py
                      CONFIGURE_COMMAND ""
                      BUILD_COMMAND env ${env}
                          ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build
                          --mpicc=${CMAKE_INSTALL_PREFIX}/bin/mpicc
                      INSTALL_COMMAND env ${env}
                          ${CMAKE_INSTALL_PREFIX}/bin/python setup.py
                          install --prefix=${CMAKE_INSTALL_PREFIX}
                      BUILD_IN_SOURCE 1 LOG_BUILD 1 LOG_INSTALL 1)
endif()

# Build libxlsxwriter.

# First copy the source files to a new location.
execute_process(COMMAND cmake -E copy_directory ${PROJECT_SOURCE_DIR}/libxlsxwriter ${PROJECT_BINARY_DIR}/libxlsxwriter
                RESULT_VARIABLE stat)

# Now tweak the Makefile to install files in the right spot.
file(READ ${PROJECT_SOURCE_DIR}/libxlsxwriter/Makefile xlsx_makefile)
string(REPLACE "install:" "install: all" xlsx_makefile ${xlsx_makefile})
string(REPLACE "cp -r include/* /usr/include" "cp -R include/* ${CMAKE_INSTALL_PREFIX}/include" xlsx_makefile ${xlsx_makefile})
string(REPLACE "cp lib/* /usr/lib" "cp lib/* ${CMAKE_INSTALL_PREFIX}/lib" xlsx_makefile ${xlsx_makefile})
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
