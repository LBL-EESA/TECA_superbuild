cmake_minimum_required(VERSION 3.0)

project(TECA_3rdparty)

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

# We need to override the default value of CMAKE_INSTALL_PREFIX.
if (CMAKE_INSTALL_PREFIX STREQUAL "/usr/local")
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR})
endif()

message("-- Installing libraries in ${CMAKE_INSTALL_PREFIX}...")

include(ExternalProject)

# Build MPICH if MPI is requested.
if (TECA_HAS_MPI)
  set(MPICH_CONFIGURE_COMMAND ${PROJECT_SOURCE_DIR}/mpich/configure --prefix=${CMAKE_INSTALL_PREFIX})
  ExternalProject_Add(mpich 
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/mpich
                      CONFIGURE_COMMAND ${MPICH_CONFIGURE_COMMAND})
endif()

# Build the HDF5 parallel I/O library. 
set(HDF5_CMAKE_COMMAND ${CMAKE_COMMAND} ../hdf5 -Wno-dev 
                       -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DHDF5_BUILD_CPP_LIB=OFF)
if (TECA_HAS_MPI)
  set(HDF5_CMAKE_COMMAND ${HDF5_CMAKE_COMMAND} -DHDF5_ENABLE_PARALLEL=ON 
                         -DMPI_C_COMPILER=${CMAKE_INSTALL_PREFIX}/bin/mpicc 
                         -DMPI_CXX_COMPILER=${CMAKE_INSTALL_PREFIX}/bin/mpicxx)
  ExternalProject_Add(hdf5 
                      DEPENDS mpich
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/hdf5
                      CMAKE_COMMAND ${HDF5_CMAKE_COMMAND})
else()
  ExternalProject_Add(hdf5 
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/hdf5
                      CMAKE_COMMAND ${HDF5_CMAKE_COMMAND})
endif()
                    
# Build NetCDF.
set(NETCDF_CMAKE_COMMAND ${CMAKE_COMMAND} ../netcdf -Wno-dev 
                         -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DENABLE_NETCDF4=ON 
                         -DENABLE_TESTS=OFF -DBUILD_EXAMPLES=OFF -DNC_HAVE_PARALLEL_HDF5=${TECA_HAS_MPI}
                         -DHDF5_IS_PARALLEL=${TECA_HAS_MPI})
ExternalProject_Add(netcdf 
                    DEPENDS hdf5
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
set(BOOST_BUILD_COMMAND ./b2)
set(BOOST_INSTALL_COMMAND ./b2 install --prefix=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(boost
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/boost
                    BUILD_IN_SOURCE 1
                    CONFIGURE_COMMAND ${BOOST_CONFIGURE_COMMAND}
                    BUILD_COMMAND ${BOOST_BUILD_COMMAND}
                    INSTALL_COMMAND ${BOOST_INSTALL_COMMAND})

# Build Python.
set(PYTHON_CONFIGURE_COMMAND env CXX=${CMAKE_CXX_COMPILER} ${PROJECT_SOURCE_DIR}/Python/configure --prefix=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(Python 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/Python
                    CONFIGURE_COMMAND ${PYTHON_CONFIGURE_COMMAND})

# Build Cython.
set(CYTHON_BUILD_COMMAND ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build install --prefix=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(Cython 
                    DEPENDS Python
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/Cython
                    BUILD_IN_SOURCE 1
                    CONFIGURE_COMMAND ""
                    BUILD_COMMAND ${CYTHON_BUILD_COMMAND}
                    INSTALL_COMMAND "")

# Build numpy.
set(NUMPY_BUILD_COMMAND ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build -j 4 install --prefix=${CMAKE_INSTALL_PREFIX})
ExternalProject_Add(numpy 
                    DEPENDS Cython
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/numpy
                    BUILD_IN_SOURCE 1
                    CONFIGURE_COMMAND ""
                    BUILD_COMMAND ${NUMPY_BUILD_COMMAND}
                    INSTALL_COMMAND "")


# Build mpi4py if requested.
if (TECA_HAS_MPI)
  set(MPI4PY_BUILD_COMMAND ${CMAKE_INSTALL_PREFIX}/bin/python setup.py build --mpicc=${CMAKE_INSTALL_PREFIX}/bin/mpicc)
  set(MPI4PY_INSTALL_COMMAND ${CMAKE_INSTALL_PREFIX}/bin/python setup.py install --prefix=${CMAKE_INSTALL_PREFIX})
  ExternalProject_Add(mpi4py 
                      DEPENDS mpich numpy 
                      SOURCE_DIR ${PROJECT_SOURCE_DIR}/mpi4py
                      BUILD_IN_SOURCE 1
                      CONFIGURE_COMMAND ""
                      BUILD_COMMAND ${MPI4PY_BUILD_COMMAND}
                      INSTALL_COMMAND ${MPI4PY_INSTALL_COMMAND})
endif()

# Build libxlsxwriter.
set(LIBXLSXWRITER_BUILD_COMMAND make)
file(WRITE ${PROJECT_BINARY_DIR}/install_libxlsxwriter "cp ${PROJECT_SOURCE_DIR}/libxlsxwriter/lib/* ${CMAKE_INSTALL_PREFIX}/lib && cp -R ${PROJECT_SOURCE_DIR}/libxlsxwriter/include/* ${CMAKE_INSTALL_PREFIX}/include")
set(LIBXLSXWRITER_INSTALL_COMMAND sh ${PROJECT_BINARY_DIR}/install_libxlsxwriter)
ExternalProject_Add(libxlsxwriter 
                    SOURCE_DIR ${PROJECT_SOURCE_DIR}/libxlsxwriter
                    BUILD_IN_SOURCE 1
                    CONFIGURE_COMMAND ""
                    BUILD_COMMAND ${LIBXLSXWRITER_BUILD_COMMAND}
                    INSTALL_COMMAND ${LIBXLSXWRITER_INSTALL_COMMAND})

