#!/usr/bin/env bash

set -e          # script stops on error
set -u          # error if undefined variable
set -o pipefail # script fails if piped command fails

__version='Ren 1.0'

function show_usage() {
    echo "Usage: $0 [ -n ] perlexpr files"
}

function show_version() {
    echo "Version: $__version"
}

function parse_args() {
    # Read options
    while getopts 'nv' opt; do
        case "$opt" in
        n)
            renameOptions+=(-n)
            ;;
        v)
            show_version
            exit 0
            ;;
        *)
            show_usage
            exit 1
            ;;
        esac
    done
    shift "$(($OPTIND - 1))"

    # Read "perlexpr" argument
    if [ -z "$1" ]; then
        show_usage
        exit 1
    else
        perlexpr="$1"
        shift
    fi

    # Read "files" argument
    if [ -z "$1" ]; then
        show_usage
        exit 1
    else
        files=("$@")
    fi
}

# $1: perlexpr
# $2: file index
function inject_counter() {
    local placeholder=$(echo $1 | grep -Pio '(?<!\\)\[(C)\d*(\+|:)?\d*:?\d*(?<!\\)\]')
    if [ -z "$placeholder" ]; then
        echo $1
        return
    fi

    # Find "start at" option in counter placeholder
    local startAt=$(echo "$placeholder" | grep -Pio '(?<=C)\d*')
    if [ -z $startAt ]; then
        startAt=1
    fi

    # Find "step by" option in counter placeholder
    local stepBy=$(echo "$placeholder" | grep -Pio '(?<=\+)\d*')
    if [ -z $stepBy ]; then
        stepBy=1
    fi

    # Find "didits width" option in counter placeholder
    local digitsWidth=$(echo "$placeholder" | grep -Pio '(?<=\:)\d*')
    if [ -z $digitsWidth ]; then
        digitsWidth=1
    fi

    # Calculate and format counter value based on digits width
    printf -v counter "%0${digitsWidth}d" $(($startAt + $2 * $stepBy))

    # Return "perlexpr" that has counter placeholder replaced with counter value
    echo "${1/"$placeholder"/"$counter"}"
}

function run() {
    # Default settings
    local perlexpr=''
    local files=()
    local renameOptions=()

    parse_args "$@"

    for i in ${!files[@]}; do
        local file=${files[$i]}
        local renamePerlexpr="$(inject_counter "$perlexpr" $i)"

        rename "${renameOptions[@]}" "$renamePerlexpr" "$file"
    done
}

run "$@"
