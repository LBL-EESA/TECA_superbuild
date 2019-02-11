FROM fedora:28

RUN dnf update -y && \
	dnf install -y git-all gcc-c++ make cmake findutils \
	expat-devel zlib-devel pcre-devel gcc-gfortran passwd vim

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
RUN adduser ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN passwd -d ${USER}

RUN chown -R ${USER}:${USER} ${WORKDIR}

USER ${USER}

CMD ["/bin/bash"]