# Valgrind on MacOS

Valgrind is a fantastic tool for finding memory leaks in programs you are developing, but unfortunately it doesn't work on MacOS because of Apple's security mechanisms. Apple does offer the `leaks` utility, but this is more for identifying leaks while a program is running rather than Valgrind's more comphehensive summary of what memory was not properly freed when the program terminated. There is a workaround that you can use to run valgrind on MacOS though: **Run it on Linux**.

Using Docker, you can download a Linux image and run it in a container, granting you a lightweight Linux environment on your MacOS device from which you can run any linux-only command like `valgrind`. The problem with this, however, is that containers are isolated environments, so you can't access the program you want to check for memory leaks from a container by default. **The goal of this repository, then, is to provide instructions and scripts that allow you to prepare an appropriate Linux image, give it access to your program, run valgrind in it, and then exit, all with a single command that behaves like `valgrind`**.

## Docker

To install docker desktop you can follow [these instructions](https://docs.docker.com/desktop/setup/install/mac-install/). If you prefer to only download the docker command line utility you can use your package manager to do so. MacOS does not come with a package manager, so if you haven't installed one already then you can install [Homebrew](https://brew.sh), which is the most popular and best maintained MacOS package manager.

## The Linux Image

*Note: The scripts in this repository use Ubuntu as their Linux distribution. I have done my best to make changing the distribution easy, but you will have to modify the scripts and instructions somewhat if you want to use a different distro*.

Once you have installed Docker, you can download an Ubuntu image with `docker pull ubuntu`. This is a barebones image, with hardly any utilities (like Valgrind) installed. You could run this image and install all the utilities you need every time you run it, but this would take a while every time you ran it. Instead, you can run the image, install whatever you want, and then **save the container as a new image**. Here's the full process:

```bash
# pull the Ubuntu image
docker pull ubuntu
# run a container with the Ubuntu image named my-ubuntu. -it gives you shell
# access, without -it the container would run but you couldn't access it
docker run -it --name my-ubuntu-container ubuntu

# IN THE CONTAINER

# update existing packages. you run as root in an ubuntu container, so no sudo
# is required
apt-get update
# ensure no interactive prompts during package installation. the -yq flag may
# also be necessary when using apt-get
export DEBIAN_FRONTEND=noninteractive
# install gcc to compile programs
apt-get -yq install gcc
# install make to allow for complex compilation
apt-get -yq install make
# install valgrind
apt-get -yq install valgrind
# you may also want to install gdb and g++ which, while not needed for valgrind,
# can be generally useful utilities in an Ubuntu image
#   apt-get -yq install gdb
#   apt-get -yq install g++
exit

# OUTSIDE THE CONTAINER

# save the container you just ran as a new docker image called my-ubuntu
docker commit my-ubuntu-container my-ubuntu
# remove the container, it's no longer needed
docker rm my-ubuntu-container
```

## Set up the Script

To run `run-valgrind-container.sh` from anywhere on your system, you should create a symbolic link to it from a directory in your path.

```bash
# create a link called valgrind to run-valgrind-container.sh in /usr/local/bin
ln -s [PATH_TO_SCRIPT]/run-valgrind-container.sh /usr/local/bin/valgrind
```

## Running Valgrind

Normally Valgrind takes an executable and runs it while checking for memory leaks. Unfortunately, no executable compiled for macOS can be expected to run directly in Linux because of differences in libraries and system calls. As a result, any code that must be checked for memory leaks must be compiled in the Linux environment. This is why you had to install `gcc` and `make` in the Linux image.

The scripts in this repo will handle copying the source code to Linux and recompiling it, but they must know what to compile first. **Therefore you must create a Makefile in the same directory as your code which has a rule the same name as the executable you supply**. If no such rule exists then the script will run `make` and hope for the best.

Provided you have a Makefile in the same directory as your executable, **you can use this script the same way you would use valgrind normally**.
