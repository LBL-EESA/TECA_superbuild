#!/bin/bash
set -v

# suck in package lists
dnf update -qq -y

# install deps
dnf install -qq -y environment-modules git-all gcc-c++ gcc-gfortran \
    make cmake-3.11.0-1.fc28 subversion expat-devel libffi-devel \
    pcre-devel zlib-devel libtool

echo ${TRAVIS_BRANCH}
echo ${BUILD_TYPE}
echo ${DOCKER_IMAGE}
echo ${IMAGE_VERSION}