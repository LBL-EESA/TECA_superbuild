# TECA & Docker
For convenience, instead of building TECA on different platforms, we can have TECA in any environment and build it in docker.
This way we guarantee that TECA will build without any dependency issues, and at the same time we can use whatever editor we want to use in the environment we're most comfortable with.

## Getting started
Think of the term `Dockerfile` as a recipe that Docker will read to build the image that will be used to instantiate the containers that we are going to run TECA on.

The Dockerfile(s) provided here clone the TECA_superbuild project and build everything (all the needed dependencies except the TECA project -- because we will build TECA ourselves), in `/teca_deps/2.1.3` directory.
As you will find there the command:
```
RUN git clone https://github.com/LBL-EESA/TECA_superbuild.git
RUN cd TECA_superbuild && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/teca_deps/2.1.3 -DENABLE_TECA=OFF .. \
	&& make -j4
```
### Building our Docker images
Choose the linux distribution that you want and `cd` into it. For this guide we will choose the ubuntu distro.
```
$ cd TECA_superbuild/docker_env/ubuntu18_04
$ docker build . -t superbuild_built_no_teca_ubuntu18_04
```
The `docker build` command tells Docker to look for a file named `Dockerfile` in the path provided, which is `.` current directory in our case.
And name (tag) that image using the `-t` option with the name provided, which is `superbuild_built_no_teca_ubuntu18_04` in our case.

### Sharing your filesystem with the Container we built
Let's say you have the cloned TECA project on whatever platform you are using, and you want to use an editor that you prefer,
then we will have to use the [mounting volume feature (shared filesystems) in the Docker run command](https://docs.docker.com/engine/reference/commandline/run/#mount-volume--v---read-only) for the Docker container to be able to read the TECA files on your filesystem.

```
$ cd ~/user_workspace
$ mkdir shared_with_container && cd shared_with_container
$ git clone https://github.com/LBL-EESA/TECA.git
```
For testing purposes we will need to share the testing data as well inside the `shared_with_container` directory.
```
$ svn co svn://missmarple.lbl.gov/work3/teca/TECA_data
```

In order to share your filesystem, we will have to use the `-v` in the `docker run` command using the format `${USER_HOST_DIR}:${CONTAINER_DIR}`,
 where `${USER_HOST_DIR}` represents the shared directory that we wanna share with the docker container, and `${CONTAINER_DIR}` represents the path that from the contianer's perspective it will find the shared directory as it's own directory.

For example if:
```
# USER_HOST_DIR = ~/user_workspace/shared_with_container
# CONTAINER_DIR = /user_host`
```
Then the command will be:
```
docker run -it -v ~/user_workspace/shared_with_container:/user_host superbuild_built_no_teca_ubuntu18_04 /bin/bash
```

`docker run` is the [command](https://docs.docker.com/engine/reference/commandline/run/) that instantiate a container from the image we created, `superbuild_built_no_teca_ubuntu18_04` in our case.

The previous `docker run` command should have taken us inside the container's terminal (because of the `-i` & `-t` options and the `/bin/bash` command).
We will find ourselves in the main working directory in the Container `/project`. This was specified in the `Dockerfile` using the `WORKDIR` command.

If you run this command:
```
mpi@63a06da76dd9:/project$ ls /user_host/
```
you should see the files that you just downloaded in the `shared_with_container` directory:
```
TECA  TECA_data
```

### Building TECA in the Container

The following commands to build TECA should go like this:
```
mpi@63a06da76dd9:/project$ mkdir TECA_build
mpi@63a06da76dd9:/project$ cd TECA_build/
mpi@63a06da76dd9:/project/TECA_build$ cmake -DCMAKE_INSTALL_PREFIX=/teca_deps/2.1.3 -DTECA_DATA_ROOT=/user_host/TECA_data -DBUILD_TESTING=ON /user_host/TECA
```
Then
```
mpi@63a06da76dd9:/project$ make -j4
```

Now you can edit the TECA project on your system and build the project in the container after you finish using the `make` command.
