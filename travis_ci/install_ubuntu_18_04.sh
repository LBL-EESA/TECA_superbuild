#!/bin/bash
set -v

# suck in package lists
apt-get update -qq

# install deps
# use PIP for Python packages
apt-get install -qq -y git-core gcc g++ gfortran cmake swig
    

git clone http://github.com/burlen/libxlsxwriter.git
cd libxlsxwriter
make
make install
cd ..

echo ${TRAVIS_BRANCH}
echo ${BUILD_TYPE}
echo ${DOCKER_IMAGE}
echo ${IMAGE_VERSION}
echo ${TECA_PYTHON_VERSION}
echo ${TECA_DATA_REVISION}

pip${TECA_PYTHON_VERSION} install numpy mpi4py matplotlib

# install data files.
svn co svn://missmarple.lbl.gov/work3/teca/TECA_data@${TECA_DATA_REVISION} TECA_data
