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

EXPLICIT_COMPILATION=false
COMPILATION_ARGS=""

VALGRIND_ARGS=()

# collect all args for valgrind
while [[ "$1" =~ ^-  ]]; do
    case $1 in
        -C=* | --compile-command=* )  # check for explicit compilation args
            EXPLICIT_COMPILATION=true
            COMPILATION_ARGS=${1#*=}
            ;;
        *)
            VALGRIND_ARGS+=("$1")
            ;;
    esac

    shift
done

# get the name of the executable
if [[ -f "$1" && -x "$1" ]]; then  # check if the current argument is executable
    PROGRAM_ARG="$1"
else
    echo "Error: You must include the name of an executable"
    exit 1
fi

# get the program name and parent directory separately
PROGRAM_NAME=$(basename "$PROGRAM_ARG")
PARENT_DIR=$(realpath "$(dirname "$PROGRAM_ARG")")

# check for Makefile in parent directory if EXPLICIT_COMPILATION is off
if [[ $EXPLICIT_COMPILATION = false && ! -e $PARENT_DIR/Makefile ]]; then
    echo "Error: You must include a Makefile to build your executable in the same directory as your executable"
    exit 1
fi

# add the executable name to VALGRIND_ARGS
VALGRIND_ARGS+=("./$PROGRAM_NAME")

# add the rest of the arguments to VALGRIND_ARGS
shift  # skip the executable name
while [[ -n "$1" ]]; do
    VALGRIND_ARGS+=("$1")
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
make clean > /dev/null 2>&1 || rm -f *.o "$PROGRAM_NAME"

# generate a makefile if EXPLICIT_COMPILATION is on
if [[ $EXPLICIT_COMPILATION = true ]]; then
    echo "$PROGRAM_NAME:" > Makefile
    echo -e "\t$COMPILATION_ARGS" >> Makefile
fi

# add the run-in-container script to the copied directory
cp "$SCRIPT_DIR/run-in-container.sh" "$COPY_DIR"

# run the docker container
docker run --rm \
    -v "$COPY_DIR":"$LINUX_DIR" \
    "$LINUX_IMAGE" \
    bash "$LINUX_DIR"/run-in-container.sh $VALGRIND_ARGS_STR

# delete the copied directory
rm -rf "$COPY_DIR"
