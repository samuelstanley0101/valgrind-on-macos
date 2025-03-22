#!/usr/bin/env bash

# the directory of this script
SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

# go to this script's directory
cd "$SCRIPT_DIR"

EXPLICIT_COMPILATION=false
COMPILATION_ARGS=""

# Collect all arguments for valgrind
VALGRIND_ARGS=()
while [[ -n "$1" ]]; do
    VALGRIND_ARGS+=("$1")
    shift
done

# join the array into a single string
VALGRIND_ARGS_STR="${VALGRIND_ARGS[*]}"

# parse the name of the program
for arg in "${VALGRIND_ARGS[@]}"; do
    if [[ $arg == ./* ]]; then
        PROGRAM_NAME=${arg:2}
        break
    fi
done

# compile the executable
make $PROGRAM_NAME || make || ( echo "Error: Could not make target executable" && exit 1 )

# check that the executable was created
if [[ ! -e $PROGRAM_NAME ]]; then
    echo "Error: Make ran successfully, but the target executable was not created"
    exit 1
fi

# run valgrind
valgrind $VALGRIND_ARGS_STR
