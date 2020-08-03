#!/bin/bash
set -v

# suck in package lists
dnf update -qq -y

# install deps
dnf install -qq -y environment-modules git-all gcc-c++ \
    gcc-gfortran make cmake subversion libtool

echo ${TRAVIS_BRANCH}
echo ${BUILD_TYPE}
echo ${DOCKER_IMAGE}
echo ${IMAGE_VERSION}
