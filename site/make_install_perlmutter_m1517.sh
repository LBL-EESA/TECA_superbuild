#!/bin/bash

# load the gcc environment
module load PrgEnv-gnu
module load cudatoolkit
module load cpe-cuda
module load cmake

# mpich is not in the pkg-config path on Cori
export PKG_CONFIG_PATH=${CRAY_MPICH_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}

# show what the script is doing and error out if any command fails
set -e
#set -x

# choose the branch or tag to compile.
: ${TECA_SOURCE:=develop}

# turn TECA off for a develoment install
: ${ENABLE_TECA:=ON}

# get the root of the install
TECA_REV=`git ls-remote git@github.com:LBL-EESA/TECA.git | grep ${TECA_SOURCE} |  cut -c1-8`
: ${TECA_PREFIX:=/global/common/software/m1517/perlmutter/teca}
: ${PREFIX:=${TECA_PREFIX}/${TECA_SOURCE}-${TECA_REV}}

# mark as dependency only
if [[ "${ENABLE_TECA}" != "ON" ]]
then
    echo "build and install dependencies only"
    PREFIX=${PREFIX}-deps
fi

BUILD_DIR=build-${TECA_SOURCE}-${TECA_REV}

echo "TECA is ${ENABLE_TECA}"
echo "building ${TECA_SOURCE}"
echo "build in ${BUILD_DIR}"
echo "install to ${PREFIX}"

# clone and checkout the corresponding superbuild
if [[ ! -d TECA_superbuild ]]
then
    echo "cloning the superbuild ... "
    git clone https://github.com/LBL-EESA/TECA_superbuild.git
fi
echo "updating the superbuild to ${TECA_SOURCE} ... "
cd TECA_superbuild
git checkout ${TECA_SOURCE}
git pull --rebase

# prompt to clean out the previous build and install
rm_build=n
if [[ -d ${BUILD_DIR} ]]
then
    read -p "Question: Do you want me to rm -rf ${BUILD_DIR} before ? " rm_build
    if [[ "${rm_build}" != "y" ]]
    then
        echo "WARNING: I will not rm -rf ${BUILD_DIR} before. this may lead to later build failures."
    fi
fi

rm_build_post=n
read -p "Question: Do you want me to rm -rf ${BUILD_DIR} after ? " rm_build_post
if [[ "${rm_build_post}" != "y" ]]
then
    echo "WARNING: I will not rm -rf ${BUILD_DIR} after. this may waste disk space."
fi

rm_install=n
if [[ -d ${PREFIX} ]]
then
    read -p "Question: Do you want me to rm -rf ${PREFIX} ? " rm_install
    if [[ "${rm_install}" != "y" ]]
    then
        echo "WARNING: I will not rm -rf ${PREFIX}. this may lead to later build failures."
    fi
fi

# clean out the previous build and install
if [[ "${rm_build}" == "y" ]]
then
    echo "cleaning out the old build in ${BUILD_DIR} ... "
    rm -rf ${BUILD_DIR}
fi

if [[ "${rm_install}" == "y" ]]
then
    echo "cleaning out the old install in ${PREFIX} ... "
    rm -rf ${PREFIX}
fi

# make a new build directory
echo "configuring the build in ${BUILD_DIR} ... "
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Configure TECA superbuild
cmake \
  -DCMAKE_CXX_COMPILER=`which g++` \
  -DCMAKE_C_COMPILER=`which gcc` \
  -DCMAKE_BUILD_TYPE=Release \
  -DTECA_SOURCE=${TECA_SOURCE} \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DENABLE_CUDA=ON \
  -DENABLE_MPICH=OFF \
  -DENABLE_OPENMPI=OFF \
  -DENABLE_CRAY_MPICH=ON \
  -DENABLE_TECA_TEST=OFF \
  -DENABLE_TECA_DATA=ON \
  -DENABLE_TECA=${ENABLE_TECA} \
  -DENABLE_TECA_PROFILER=OFF \
  ..

# do the build and install
echo "build and install ... "
make -j16 install

# open the install to other users
echo "opening permissions for m1517 ... "
fix_perms -g m1517 ${PREFIX}

# clean out the previous build
cd ..
if [[ "${rm_build_post}" == "y" ]]
then
    echo "cleaning out the build in ${BUILD_DIR} ... "
    rm -rf ${BUILD_DIR}
fi
