#!/bin/bash
set -v

export TECA_BUILD_CORES=2
if [[ "$DOCKER_IMAGE" == "fedora" ]]; then
    source /usr/share/Modules/init/bash
fi
mkdir build
cd build

export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

cmake --version
cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} ..
make -j${TECA_BUILD_CORES} install
