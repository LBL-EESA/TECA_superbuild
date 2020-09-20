#!/bin/bash
set -v

if [[ "$DOCKER_IMAGE" == "fedora" ]]; then
    source /usr/share/Modules/init/bash
fi
mkdir build
cd build

cmake --version
cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCTEST_FLAGS=-VV -DENABLE_TORCH=ON -DTECA_TEST_CORES=2 -DENABLE_LIBXLSXWRITER=OFF ..
make install
