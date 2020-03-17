#!/bin/bash
set -v
export DASHROOT=`pwd`
export SHA=`git log --pretty=format:'%h' -n 1`
if [[ "$DOCKER_IMAGE" == "fedora" ]]; then
    source /usr/share/Modules/init/bash
fi
mkdir build
cd build
cmake --version
ctest -S ${DASHROOT}/travis_ci/ctest_linux.cmake -V --timeout 180
