FROM ubuntu:18.04

RUN apt-get update -y && \
	apt-get install -y git-core g++ cmake pkg-config \
	subversion libexpat-dev zlib1g-dev libpcre3-dev gfortran && \
	apt-get install -y --no-install-recommends vim

#### CREATE WORKING DIRECTORY FOR USER ####
ARG WORKDIR=/project
ENV WORKDIR ${WORKDIR}
RUN mkdir ${WORKDIR}

WORKDIR ${WORKDIR}

RUN mkdir -p /teca_deps/2.1.3

RUN git clone https://github.com/LBL-EESA/TECA_superbuild.git
RUN cd TECA_superbuild && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/teca_deps/2.1.3 -DENABLE_TECA=OFF .. \
	&& make -j4

#### ADD DEFAULT USER ####
ARG USER=mpi
ENV USER ${USER}
RUN adduser --disabled-password --gecos "" ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R ${USER}:${USER} ${WORKDIR}

USER ${USER}

CMD ["/bin/bash"]