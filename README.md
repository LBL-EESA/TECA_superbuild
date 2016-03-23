# TECA 3rd-party libraries
This repo contains the 3rd-party dependencies for TECA. You can install these 
dependencies by creating a build directory and invoking cmake thus:

```bash
$ mkdir build && cd build
$ cmake .. -DTECA_HAS_MPI=ON \
           -DCMAKE_C_COMPILER=<C compiler> \
           -DCMAKE_CXX_COMPILER=<C++ compiler> \
           -DCMAKE_INSTALL_PREFIX=<prefix> \
           -DTECA_PLATFORM=<generic|sandybridge> 
$ make -j <number of build threads>
```
