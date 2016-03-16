# TECA 3rd-party libraries
This repo contains the 3rd-party dependencies for TECA. You can install these 
dependencies by creating a build directory and invoking cmake thus:

```bash
$ mkdir build && cd build
$ cmake .. -DTECA_HAS_MPI=ON -DCMAKE_INSTALL_PREFIX=<prefix>
$ make -j <number of build threads>
```
