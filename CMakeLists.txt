cmake_minimum_required(VERSION 3.0)

project(TECA_superbuild)
include(ExternalProject)
include(version.cmake)

# where various resources are housed and served
set(TECA_URL "http://github.com/LBL-EESA/TECA"
    CACHE STRING "URL to the TECA source code repository")

set(TECA_DATA_URL "svn://svn.code.sf.net/p/teca/TECA_data"
    CACHE STRING "URL to the TECA regresion test data repository")

set(TECA_DEPS_URL "https://sourceforge.net/projects/teca/files/TECA_deps"
    CACHE STRING "URL to the dependency tarballs")

set(LIBXLSXWRITER_URL http://github.com/burlen/libxlsxwriter.git)
set(SHAPELIB_URL https://github.com/OSGeo/shapelib.git)


# set defaults for the compute capability and test cores
set(CUDA_COMPUTE_CAPABILITY 80)
set(TECA_TEST_CORES 8)
message(STATUS "CUDA Compute Capability is ${CUDA_COMPUTE_CAPABILITY}")



# The following versions of each library are installed by this script:
set(MPICH_SOURCE mpich-3.3.1)
set(OPENMPI_SOURCE openmpi-4.0.4)
set(OPENSSL_SOURCE openssl-1.1.1g)
set(EXPAT_SOURCE expat-2.2.9)
set(ZLIB_SOURCE zlib-1.2.11)
set(HDF5_SOURCE hdf5-1.14.2)
set(NETCDF_SOURCE netcdf-c-4.9.2)
set(UDUNITS_SOURCE udunits-2.2.26)
set(BOOST_SOURCE boost_1_73_0)
set(NCURSES_SOURCE ncurses-6.2)
set(READLINE_SOURCE readline-8.0)
set(LIBFFI_SOURCE libffi-3.3)
set(PYTHON_SOURCE Python-3.8.5)
set(PCRE_SOURCE pcre-8.44)
set(SWIG_SOURCE swig-4.0.2)
set(CYTHON_SOURCE Cython-0.29.21)
set(NUMPY_SOURCE numpy-1.19.1)
set(MPI4PY_SOURCE mpi4py-3.0.3)
set(LIBXLSXWRITER_SOURCE cmake_configure)
set(SHAPELIB_SOURCE 21ae8fc16)
set(TECA_SOURCE 5.0.0 CACHE STRING
    "branch to checkout from the TECA git repository")

# extract version numbers
get_package_version(${PYTHON_SOURCE} Python PYTHON)
get_package_version(${MPICH_SOURCE} mpich MPICH)
get_package_version(${OPENMPI_SOURCE} openmpi OPENMPI)
get_package_version(${ZLIB_SOURCE} zlib ZLIB)
get_package_version(${OPENSSL_SOURCE} openssl OPENSSL)
get_package_version(${EXPAT_SOURCE} expat EXPAT)
get_package_version(${HDF5_SOURCE} hdf5 HDF5)
get_package_version(${NETCDF_SOURCE} netcdf-c NETCDF)
get_package_version(${UDUNITS_SOURCE} udunits UDUNITS)
get_package_version(${BOOST_SOURCE} boost BOOST)
get_package_version_2(${NCURSES_SOURCE} ncurses NCURSES)
get_package_version_2(${LIBFFI_SOURCE} libffi LIBFFI)
get_package_version_2(${READLINE_SOURCE} readline READLINE)
get_package_version(${PYTHON_SOURCE} Python PYTHON)
get_package_version_2(${PCRE_SOURCE} pcre PCRE)
get_package_version(${SWIG_SOURCE} swig SWIG)
get_package_version(${CYTHON_SOURCE} Cython CYTHON)
get_package_version(${NUMPY_SOURCE} numpy NUMPY)
get_package_version(${MPI4PY_SOURCE} mpi4py MPI4PY)
set(MATPLOTLIB_VERSION 3.3.4)
set(TCPYPI_VERSION 1.3.4)
set(TORCH_VERSION 2.1.0)
set(TORCHAUDIO_VERSION 2.1.0)
set(TORCHVISION_VERSION 0.16.0)
set(CUPY_VERSION cuda12x)
set(PYTORCH_CUDA_VERSION cu121)

# enable/disable each piece, all on by default
option(ENABLE_CUDA "configures for use with CUDA" OFF)
option(ENABLE_BOOST "builds and installs Boost" ON)
option(ENABLE_LIBXLSXWRITER "builds and installs libxlsxwriter" ON)
option(ENABLE_SHAPELIB "builds and installs OSGeo shapelib" ON)
option(ENABLE_MPICH "builds and installs MPICH MPI" OFF)
option(ENABLE_OPENMPI "builds and installs OpenMPI MPI" ON)
option(ENABLE_CRAY_MPICH "Auto detect MPICH configuration for Cray systems" OFF)
option(WITHOUT_MPI "Disable all dependence on MPI" OFF)
option(ENABLE_NETCDF "builds and installs NetCDF group" ON)
option(ENABLE_PYTHON "builds and installs Python group" ON)
option(ENABLE_READLINE "builds and installs readline" OFF)
option(ENABLE_MATPLOTLIB "installs matplotlib via pip" ON)
option(ENABLE_TCPYPI "installs tcpyPI via pip" ON)
option(ENABLE_PYTORCH "installs pytorch via pip" ON)
option(ENABLE_TECA "builds and installs TECA" ON)
option(ENABLE_TECA_TEST "runs the TECA regression tests" ON)
option(ENABLE_TECA_PROFILER "compiles TECA's profiler" OFF)
option(ENABLE_TECA_DATA "downloads the TECA test datasets" ON)
option(ENABLE_UDUNITS "builds and installs UDUNITS" ON)
option(ENABLE_OPENSSL "builds and installs OpenSSL" OFF)
option(ENABLE_EXPAT "builds and installs expat" ON)
option(ENABLE_MEMCHECK "configures for use with valgrind" OFF)

# the list of enabled dependencies
set(teca_deps)
set(teca_flags)

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
        # use pkg-config to detect MPI dependencies
        set(ENV{PKG_CONFIG_PATH} "$ENV{CRAY_MPICH_DIR}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
        find_package(PkgConfig QUIET)
        pkg_check_modules(CRAY_MPICH REQUIRED QUIET mpich)
        set(MPI_C_INCLUDE_PATH ${CRAY_MPICH_INCLUDE_DIRS} CACHE STRING "MPI include directories")
        set(MPI_C_LIBRARIES ${CRAY_MPICH_LDFLAGS} CACHE STRING "MPI link dependencies")
        set(MPIEXEC srun CACHE STRING "Platform MPI run equivalent")
        set(MPI_C_FOUND CACHE BOOL ON "status of MPI config")
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
        PYTHONPATH=${CMAKE_INSTALL_PREFIX}/lib:${CMAKE_INSTALL_PREFIX}/lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages/)
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

# configure the environment module that will let us reproduce
# the build enviornment at run-time
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/modulefiles/teca.in
    ${CMAKE_CURRENT_BINARY_DIR}/modulefiles/teca/${TECA_SOURCE} @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/modulefiles/teca/${TECA_SOURCE}
    DESTINATION ${CMAKE_INSTALL_PREFIX}/modulefiles/teca)

# Build MPICH if MPI is requested.
if (NOT WITHOUT_MPI AND ENABLE_CRAY_MPICH)
    build_status(MPICH ${MPICH_VERSION} Disabled)
    build_status("Cray MPICH" "x" Enabled)
    build_status(OpenMPI ${OPENMPI_VERSION} Disabled)
    list(APPEND teca_flags "-DENABLE_CRAY_MPICH=ON")
    list(APPEND teca_flags "-DREQUIRE_MPI=TRUE")
elseif (NOT WITHOUT_MPI AND ENABLE_MPICH)
    build_status(MPICH ${MPICH_VERSION} Enabled)
    build_status("Cray MPICH" "x" Disabled)
    build_status(OpenMPI ${OPENMPI_VERSION} Disabled)
    list(APPEND teca_flags "-DREQUIRE_MPI=TRUE")
    ExternalProject_Add(mpi
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${MPICH_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPICH_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${MPICH_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --disable-maintainer-mode --enable-threads=multiple
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
elseif (NOT WITHOUT_MPI AND ENABLE_OPENMPI)
    build_status(MPICH ${MPICH_VERSION} Disabled)
    build_status("Cray MPICH" "x" Disabled)
    build_status(OpenMPI ${OPENMPI_VERSION} Enabled)
    list(APPEND teca_flags "-DREQUIRE_MPI=TRUE")
    ExternalProject_Add(mpi
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${OPENMPI_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${OPENMPI_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${OPENMPI_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --enable-mpi-thread-multiple
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    build_status(MPICH ${MPICH_VERSION} Disabled)
    build_status("Cray MPICH" "x" Disabled)
    build_status(OpenMPI ${OPENMPI_VERSION} Disabled)
endif()

# zlib
if (ENABLE_PYTHON OR ENABLE_NETCDF OR ENABLE_LIBXLSXWRITER OR ENABLE_OPENSSL)
    build_status(zlib ${ZLIB_VERSION} Enabled)
    ExternalProject_Add(zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${ZLIB_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}
        CONFIGURE_COMMAND env ${env}
             ${PROJECT_BINARY_DIR}/${ZLIB_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    build_status(zlib ${ZLIB_VERSION} Disabled)
endif()

# OpenSSL
if (ENABLE_OPENSSL)
    build_status(OpenSSL ${OPENSSL_VERSION} Enabled)
    list(APPEND teca_deps openssl)
    ExternalProject_Add(openssl
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${OPENSSL_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${OPENSSL_SOURCE}
        CONFIGURE_COMMAND env ${env}
             ${PROJECT_BINARY_DIR}/${OPENSSL_SOURCE}/config
            enable-ssl3 enable-ssl3-method --prefix=${CMAKE_INSTALL_PREFIX} ${c_flags}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    build_status(OpenSSL ${OPENSSL_VERSION} Disabled)
endif()

# expat
if (ENABLE_EXPAT)
    build_status(expat ${EXPAT_VERSION} Enabled)
    ExternalProject_Add(expat
        DEPENDS zlib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${EXPAT_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${EXPAT_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${EXPAT_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared --without-xmlwf --without-docbook
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    build_status(expat ${EXPAT_VERSION} Disabled)
endif()

# NetCDF group
if (ENABLE_NETCDF)
    # Build the HDF5 parallel I/O library.
    # for thread safety add: --enable-unsupported --enable-threadsafe
    build_status(HDF5 ${HDF5_VERSION} Enabled)
    set(hdf5_deps zlib)
    set(HDF5_CONFIG_FLAGS --enable-hl --enable-build-mode=production)
    if (NOT WITHOUT_MPI)
        if (ENABLE_CRAY_MPICH)
            set(mpi_compiler CC=cc CXX=CC)
        elseif (ENABLE_MPICH OR ENABLE_OPENMPI)
            list(APPEND hdf5_deps mpi)
            set(mpi_compiler CC=${CMAKE_INSTALL_PREFIX}/bin/mpicc CXX=${CMAKE_INSTALL_PREFIX}/bin/mpicxx)
        endif()
        list(APPEND HDF5_CONFIG_FLAGS --enable-parallel)
    endif()
    ExternalProject_Add(hdf5
        DEPENDS ${hdf5_deps}
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${HDF5_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${HDF5_SOURCE}
        CONFIGURE_COMMAND env ${env} ${mpi_compiler} ${PROJECT_BINARY_DIR}/${HDF5_SOURCE}/configure
          --prefix=${CMAKE_INSTALL_PREFIX} ${HDF5_CONFIG_FLAGS} --enable-shared --disable-static
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build NetCDF.${CMAKE_C_COMPILER} ${CMAKE_CXX_COMPILER}
    build_status(NetCDF ${NETCDF_VERSION} Enabled)
    list(APPEND teca_deps netcdf)
    list(APPEND teca_flags "-DREQUIRE_NETCDF=TRUE")
    ExternalProject_Add(netcdf
        DEPENDS hdf5
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NETCDF_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NETCDF_SOURCE}
        CONFIGURE_COMMAND env ${env} ${mpi_compiler} ${PROJECT_BINARY_DIR}/${NETCDF_SOURCE}/configure
          --prefix=${CMAKE_INSTALL_PREFIX} --enable-shared --disable-static --disable-dap
          --enable-netcdf-4 --enable-parallel4
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    build_status(HDF5 ${HDF5_VERSION} Disabled)
    build_status(NetCDF ${NETCDF_VERSION} Disabled)
endif()

# Build UDUnits.
if (ENABLE_UDUNITS)
    build_status(UDUNITS ${UDUNITS_VERSION} Enabled)
    list(APPEND teca_deps udunits)
    list(APPEND teca_flags "-DREQUIRE_UDUNITS=TRUE")
    ExternalProject_Add(udunits
        DEPENDS expat
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
    build_status(UDUNITS ${UDUNITS_VERSION} Disabled)
endif()

# Build Boost.
if (ENABLE_BOOST)
    build_status(Boost ${BOOST_VERSION} Enabled)
    list(APPEND teca_deps boost)
    list(APPEND teca_flags "-DREQUIRE_BOOST=TRUE")
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
    build_status(Boost ${BOOST_VERSION} Disabled)
endif()

# Python group
if (ENABLE_PYTHON)
    set(py_deps ncurses zlib libffi)
    # ncurses
    build_status(ncurses ${NCURSES_VERSION} Enabled)
    ExternalProject_Add(ncurses
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NCURSES_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${NCURSES_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # libffi
    build_status(libffi ${LIBFFI_VERSION} Enabled)
    ExternalProject_Add(libffi
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${LIBFFI_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${LIBFFI_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${LIBFFI_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # readline
    if (ENABLE_READLINE)
        list(APPEND py_deps readline)
        build_status(readline ${READLINE_VERSION} Enabled)
        ExternalProject_Add(readline
            DEPENDS ncurses
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${READLINE_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}
            CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${READLINE_SOURCE}/configure
                --prefix=${CMAKE_INSTALL_PREFIX}
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
    else()
        build_status(readline ${READLINE_VERSION} Disabled)
    endif()

    # Build Python.
    build_status(Python ${PYTHON_VERSION} Enabled)
    list(APPEND teca_flags "-DREQUIRE_PYTHON=TRUE")
    ExternalProject_Add(Python
        DEPENDS ${py_deps}
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${PYTHON_SOURCE}.tgz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${PYTHON_SOURCE}/configure
            --with-system-expat --with-ensurepip=yes --enable-shared
            --prefix=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # pcre
    build_status(pcre ${PCRE_VERSION} Enabled)
    ExternalProject_Add(pcre
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${PCRE_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${PCRE_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${PCRE_SOURCE}/configure
            --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Swig.
    build_status(SWIG ${SWIG_VERSION} Enabled)
    list(APPEND teca_deps SWIG)
    ExternalProject_Add(SWIG
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${SWIG_SOURCE}.tar.gz
        DEPENDS Python
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}
        CONFIGURE_COMMAND env ${env} ${PROJECT_BINARY_DIR}/${SWIG_SOURCE}/configure
            --with-python=${CMAKE_INSTALL_PREFIX}/bin/python3 --prefix=${CMAKE_INSTALL_PREFIX}
        BUILD_COMMAND env ${env} make -j
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)

    # Build Cython.
    build_status(Cython ${CYTHON_VERSION} Enabled)
    ExternalProject_Add(Cython
        DEPENDS Python
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${CYTHON_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${CYTHON_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
            setup.py build install --prefix=${CMAKE_INSTALL_PREFIX}
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

    # Build numpy.
    build_status(NumPy ${NUMPY_VERSION} Enabled)
    list(APPEND teca_deps numpy)
    ExternalProject_Add(numpy
        DEPENDS Python Cython
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        URL ${TECA_DEPS_URL}/${NUMPY_SOURCE}.tar.gz
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${NUMPY_SOURCE}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND env ${env} NPY_DISTUTILS_APPEND_FLAGS=1
           ${CMAKE_INSTALL_PREFIX}/bin/python3 setup.py build install
           "--prefix=${CMAKE_INSTALL_PREFIX}"
        INSTALL_COMMAND ""
        BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

    # Build mpi4py if MPI was requested.
    set(tmp "MPICH")
    if (DEFINED ENV{NERSC_HOST})
        set(tmp $ENV{NERSC_HOST})
    endif()
    set(MPI4PY_CONFIG ${tmp} CACHE STRING
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
        build_status(mpi4py ${MPI4PY_VERSION} Enabled)
        list(APPEND teca_deps mpi4py)
        ExternalProject_Add(mpi4py
            DEPENDS ${mpi4py_deps}
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            URL ${TECA_DEPS_URL}/${MPI4PY_SOURCE}.tar.gz
            SOURCE_DIR ${PROJECT_BINARY_DIR}/${MPI4PY_SOURCE}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python3 setup.py build
                --mpi=${MPI4PY_CONFIG},${PROJECT_BINARY_DIR}/mpi4py.cfg
            INSTALL_COMMAND env ${env}
                ${CMAKE_INSTALL_PREFIX}/bin/python3 setup.py
            install --prefix=${CMAKE_INSTALL_PREFIX}
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1 LOG_INSTALL 1)
    else()
        build_status(mpi4py ${MPI4PY_VERSION} Disabled)
    endif()

    if (ENABLE_MATPLOTLIB)
        # install matplotlib
        build_status(matplotlib ${MATPLOTLIB_VERSION} Enabled)
        list(APPEND teca_deps matplotlib)
        ExternalProject_Add(matplotlib
            DEPENDS Python numpy
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${PROJECT_BINARY_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
                -mpip install matplotlib==${MATPLOTLIB_VERSION}
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
    else()
        build_status(matplotlib ${MATPLOTLIB_VERSION} Disabled)
    endif()

    if (ENABLE_PYTORCH)
        if (ENABLE_CUDA)
            set(PYTORCH_DEV ${PYTORCH_CUDA_VERSION})
        else()
            set(PYTORCH_DEV cpu)
        endif()
        # install pytorch
        build_status(pytorch "${TORCH_VERSION}+${PYTORCH_DEV}" Enabled)
        list(APPEND teca_deps pytorch)
        ExternalProject_Add(pytorch
            DEPENDS Python numpy
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${PROJECT_BINARY_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
                -mpip install torch==${TORCH_VERSION}+${PYTORCH_DEV}
                torchvision==${TORCHVISION_VERSION}+${PYTORCH_DEV}
                torchaudio==${TORCHAUDIO_VERSION}+${PYTORCH_DEV}
                -f https://download.pytorch.org/whl/${PYTORCH_DEV}/torch_stable.html
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
    else()
        build_status(pytorch ${TORCH_VERSION} Disabled)
    endif()

    if (ENABLE_TCPYPI)
        # install tcpyPI
        build_status(tcpyPI ${TCPYPI_VERSION} Enabled)
        list(APPEND teca_deps tcpyPI)

        # numba
        ExternalProject_Add(numba
            DEPENDS Python numpy
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${PROJECT_BINARY_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
                -mpip install numba==0.53.1
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)

        # tcpyPI
        ExternalProject_Add(tcpyPI
            DEPENDS Python numpy numba
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${PROJECT_BINARY_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
                -mpip install tcpyPI==${TCPYPI_VERSION} --no-dependencies
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
    else()
        build_status(tcpyPI ${TCPYPI_VERSION} Disabled)
    endif()

    if (ENABLE_CUDA)
        # install cupy
        build_status(cupy ${CUPY_VERSION} Enabled)
        list(APPEND teca_deps cupy)
        ExternalProject_Add(cupy
            DEPENDS Python numpy
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${PROJECT_BINARY_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND env ${env} ${CMAKE_INSTALL_PREFIX}/bin/python3
                -mpip install cupy-${CUPY_VERSION}
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1 LOG_DOWNLOAD 1 LOG_BUILD 1)
    else()
        build_status(cupy ${CUPY_VERSION} Disabled)
    endif()

else()
    build_status(ncurses ${NCURSES_VERSION} Disabled)
    build_status(libffi ${LIBFFI_VERSION} Disabled)
    build_status(readline ${READLINE_VERSION} Disabled)
    build_status(Python ${PYTHON_VERSION} Disabled)
    build_status(pcre ${PCRE_VERSION} Disabled)
    build_status(SWIG ${SWIG_VERSION} Disabled)
    build_status(Cython ${CYTHON_VERSION} Disabled)
    build_status(NumPy ${NUMPY_VERSION} Disabled)
    build_status(mpi4py ${MPI4PY_VERSION} Disabled)
    build_status(matplotlib ${MATPLOTLIB_VERSION} Disabled)
    build_status(pytorch ${PYTORCH_VERSION} Disabled)
    build_status(tcpyPI ${TCPYPI_VERSION} Disabled)
    build_status(cupy ${CUPY_VERSION} Disabled)
endif()

# Build libxlsxwriter.
if (ENABLE_LIBXLSXWRITER)
    message(STATUS "LIBXLSXWRITER .......... Enabled")
    list(APPEND teca_deps libxlsxwriter zlib)
    list(APPEND teca_flags "-DREQUIRE_LIBXLSXWRITE=TRUE")
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
            "-DCMAKE_C_FLAGS=${c_flags}"
            "-DCMAKE_C_FLAGS_DEBUG=${c_flags}"
            "-DCMAKE_C_FLAGS_RELEASE=${c_flags}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${cxx_flags}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${cxx_flags}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${cxx_flags}"
            "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "LIBXLSXWRITER .......... Disabled")
endif()

# Build libxlsxwriter.
if (ENABLE_SHAPELIB)
    message(STATUS "shapelib ............... Enabled")
    list(APPEND teca_deps shapelib)
    list(APPEND teca_flags "-DREQUIRE_SHAPELIB=TRUE")
    ExternalProject_Add(shapelib
        DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
        #URL ${TECA_DEPS_URL}/${SHAPELIB_SOURCE}.tar.gz
        GIT_REPOSITORY ${SHAPELIB_URL}
        GIT_TAG ${SHAPELIB_SOURCE}
        UPDATE_COMMAND ""
        SOURCE_DIR ${PROJECT_BINARY_DIR}/${SHAPELIB_SOURCE}
        CMAKE_COMMAND env ${env} ${CMAKE_COMMAND}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            "-DCMAKE_C_FLAGS=${c_flags}"
            "-DCMAKE_C_FLAGS_DEBUG=${c_flags}"
            "-DCMAKE_C_FLAGS_RELEASE=${c_flags}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${cxx_flags}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${cxx_flags}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${cxx_flags}"
            "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1)
else()
    message(STATUS "shapelib ............... Disabled")
endif()

# TECA proper
if (ENABLE_TECA)
    build_status(TECA ${TECA_SOURCE} Enabled)
    # download the regression test data
    set(TECA_DATA_REV "-rHEAD")
    set(TECA_DATA_UPDATE svn update)
    set(TECA_UPDATE git pull --rebase)
    if (TECA_SOURCE STREQUAL "2.0.0")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r24")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "2.1.0" OR TECA_SOURCE STREQUAL "2.1.1"
	    OR TECA_SOURCE STREQUAL "2.1.2" OR TECA_SOURCE STREQUAL "2.1.3"
        OR TECA_SOURCE STREQUAL "2.2.0" OR TECA_SOURCE STREQUAL "2.2.2")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r34")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "3.0.0")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r49")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "4.0.0")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r101")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "4.1.0")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r117")
        set(TECA_DATA_UPDATE "")
    elseif (TECA_SOURCE STREQUAL "5.0.0" OR TECA_SOURCE STREQUAL "master")
        set(TECA_UPDATE "")
        set(TECA_DATA_REV "-r137")
        set(TECA_DATA_UPDATE "")
    endif()
    set(tmp)
    if (ENABLE_TECA_DATA)
        build_status(TECA_data ${TECA_DATA_REV} Enabled)
        list(APPEND teca_deps TECA_data)
        ExternalProject_Add(TECA_data
            DOWNLOAD_DIR ${PROJECT_BINARY_DIR}
            SVN_REPOSITORY ${TECA_DATA_URL}
            SVN_REVISION ${TECA_DATA_REV}
            UPDATE_COMMAND ${TECA_DATA_UPDATE}
            CONFIGURE_COMMAND "" BUILD_COMMAND ""
            INSTALL_COMMAND "" LOG_DOWNLOAD 1)
        set(tmp ${PROJECT_BINARY_DIR}/TECA_data-prefix/src/TECA_data)
    else()
        build_status(TECA_data ${TECA_DATA_REV} Disabled)
    endif()
    set(TECA_DATA_ROOT ${tmp} CACHE PATH "Path to TECA regression test data")
    if (ENABLE_TECA_TEST)
        message(STATUS "TECA tests ............. Enabled")
    else()
        message(STATUS "TECA tests ............. Disabled")
    endif()
    if (ENABLE_TECA_PROFILER)
        message(STATUS "TECA profiler .......... Enabled")
    else()
        message(STATUS "TECA profiler .......... Disabled")
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
            -DTECA_CUDA_ARCHITECTURES=${CUDA_COMPUTE_CAPABILITY}
            -DCMAKE_CUDA_ARCHITECTURES=${CUDA_COMPUTE_CAPABILITY}
            "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS}"
            "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS}"
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            "-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"
            "-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            ${teca_flags} ${MPI_FLAGS} -DTECA_HAS_VTK=OFF
            -DTECA_PYTHON_VERSION=3 -DTECA_DATA_ROOT=${TECA_DATA_ROOT}
            -DBUILD_TESTING=${ENABLE_TECA_TEST}
            -DREQUIRE_CUDA=${ENABLE_CUDA}
            -DTECA_ENABLE_PROFILER=${ENABLE_TECA_PROFILER}
            -DHAMR_LIBRARY_TYPE=SHARED
            -DBUILD_SHARED_LIBS=ON
            -DTECA_TEST_CORES=${TECA_TEST_CORES}
            ${PROJECT_BINARY_DIR}/TECA
        TEST_AFTER_INSTALL ${ENABLE_TECA_TEST}
        TEST_COMMAND env ${env} ctest ${CTEST_FLAGS} || true
        LOG_DOWNLOAD 1 LOG_CONFIGURE 0 LOG_BUILD 0 LOG_INSTALL 0)
else()
    build_status(TECA ${TECA_SOURCE} Disabled)
    message(STATUS "TECA_data .............. Disabled")
    message(STATUS "TECA tests ............. Disabled")
    message(STATUS "TECA profiler .......... Disabled")
endif()
