#!/usr/bin/env bash

# CHANGE THIS IF YOU NAMED YOUR LINUX IMAGE SOMETHING ELSE
LINUX_IMAGE="my-ubuntu"
# the directory that the source code will be copied to in the container
LINUX_DIR="/tmp/valgrind_dir"

# the directory of this script
SCRIPT_DIR=$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")

PROGRAM_ARG=""
PROGRAM_NAME=""
PARENT_DIR=""
COPY_DIR=""

# Collect all arguments for valgrind
VALGRIND_ARGS=()
for arg in "$@"; do
    VALGRIND_ARGS+=("$arg")
done

# try to find an executable in the argument list
for i in "${VALGRIND_ARGS[@]}"; do
    if [[ -f $i ]] && [[ -x $i ]]; then  # check if i is an executable
        PROGRAM_ARG="$i"
        break
    fi
done

# check that an executable was found
if [[ -z $PROGRAM_ARG ]]; then
    echo "Error: You must include the name of an executable"
    exit 1
fi

# get the program name and parent directory separately
PROGRAM_NAME=$(basename "$PROGRAM_ARG")
PARENT_DIR=$(realpath "$(dirname "$PROGRAM_ARG")")

# check for Makefile in parent directory
if [[ ! -e $PARENT_DIR/Makefile ]]; then
    echo "Error: You must include a Makefile to build your executable in the same directory as your executable"
    exit 1
fi

# replace the original executable path with a relative path in VALGRIND_ARGS
for i in "${!VALGRIND_ARGS[@]}"; do
    if [[ "${VALGRIND_ARGS[$i]}" == "$PROGRAM_ARG" ]]; then
        VALGRIND_ARGS[$i]="./${PROGRAM_NAME}"
        break
    fi
done

# join the array into a single string
VALGRIND_ARGS_STR="${VALGRIND_ARGS[*]}"

# copy the parent directory to a temporary directory
COPY_DIR=$(mktemp -d "/tmp/${PROGRAM_NAME}_dir_copy_XXXXXX")
if [[ -z $COPY_DIR ]]; then
    echo "Failed to create copy directory"
    exit 1
fi
cp -r "$PARENT_DIR"/* "$COPY_DIR"

# go to the copied directory
cd "$COPY_DIR" || exit

# make the copied directory clean
make clean || rm -f *.o "$PROGRAM_NAME"

# add the run-in-container script to the copied directory
cp "$SCRIPT_DIR/run-in-container.sh" "$COPY_DIR"

# run the docker container
docker run --rm \
    -v "$COPY_DIR":"$LINUX_DIR" \
    "$LINUX_IMAGE" \
    bash "$LINUX_DIR"/run-in-container.sh $VALGRIND_ARGS_STR

# delete the copied directory
rm -rf "$COPY_DIR"
