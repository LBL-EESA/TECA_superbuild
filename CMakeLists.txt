cmake_minimum_required(VERSION 3.0)

project(TECA_3rdparty)

# The following versions of each library are installed by this script:
# MPICH:   
# HDF5:          1.8.16
# NetCDF:        4.4.0
# UDUnits:       2.2.20
# Python:        2.7.11
# Numpy:
# Mpi4py:
# Boost:         1_60_0
# Libxlsxwriter: 

option(TECA_HAS_MPI "Build parallel libraries for TECA" ON)

# We need to override the default value of CMAKE_INSTALL_PREFIX.
if (CMAKE_INSTALL_PREFIX STREQUAL "/usr/local")
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR})
endif()

message("-- Installing libraries in ${CMAKE_INSTALL_PREFIX}...")

include(ExternalProject)

# Build the HDF5 parallel I/O library. 
set(HDF5_CMAKE_COMMAND ${CMAKE_COMMAND} ../hdf5 -Wno-dev 
                       -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DHDF5_BUILD_CPP_LIB=OFF)
if (TECA_HAS_MPI)
  set(HDF5_CMAKE_COMMAND ${HDF5_CMAKE_COMMAND} -DHDF5_ENABLE_PARALLEL=ON)
endif()
ExternalProject_Add(hdf5 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/hdf5
                    CMAKE_COMMAND ${HDF5_CMAKE_COMMAND})
                    
# Build NetCDF.
set(NETCDF_CMAKE_COMMAND ${CMAKE_COMMAND} ../netcdf -Wno-dev 
                         -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DENABLE_NETCDF4=ON 
                         -DENABLE_TESTS=OFF -DBUILD_EXAMPLES=OFF -DNC_HAVE_PARALLEL_HDF5=${TECA_HAS_MPI}
                         -DHDF5_IS_PARALLEL=${TECA_HAS_MPI})
ExternalProject_Add(netcdf 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/netcdf
                    CMAKE_COMMAND ${NETCDF_CMAKE_COMMAND})

# Build UDUnits.
set(UDUNITS_CMAKE_COMMAND ${CMAKE_COMMAND} ../udunits -Wno-dev 
                         -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(udunits 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/udunits
                    CMAKE_COMMAND ${UDUNITS_CMAKE_COMMAND})

# Build Boost.
set(BOOST_CONFIGURE_COMMAND sh bootstrap.sh --prefix=${CMAKE_INSTALL_PREFIX} --with-libraries=program_options)
ExternalProject_Add(boost
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/boost
                    BUILD_IN_SOURCE 1
                    CONFIGURE_COMMAND ${BOOST_CONFIGURE_COMMAND}
                    BUILD_COMMAND ./b2)

# Build Python.
set(PYTHON_CONFIGURE_COMMAND ${PROJECT_SOURCE_DIR}/Python/configure --prefix=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(Python 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/Python
                    CONFIGURE_COMMAND ${PYTHON_CONFIGURE_COMMAND})

