#!/usr/bin/env bash

set -e          # script stops on error
set -u          # error if undefined variable
set -o pipefail # script fails if piped command fails

__name='ren'
__version='Ren version 1.0'

function show_usage() {
    cat <<EOF
Usage:
    $__name [ -h|-v ] [ -n ] perlexpr files

Options:
    -n, --nono
        Print names of files to be renamed, but don't rename.

    -h, --help
        Print synopsis, options and examples.

    -v, --version
        Show version number.

Examples:
    ren 's/.*/clipart-[C].png/' *.png
    ren 's/(.*)\.(.*)/\$1-[C:5].\$2/' *.*

Full documentation at: https://github.com/linogefly/ren
EOF
}

function show_version() {
    echo "$__version"
}

function parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
        -h | --help)
            show_usage
            exit 0
            ;;
        -v | --version)
            show_version
            exit 0
            ;;
        -n | --dry-run)
            renameOptions+=(-n)
            shift
            ;;
        -* | --*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            # First non option argument is "perlexpr"
            if [ -z "$perlexpr" ]; then
                perlexpr="$1"
                shift
            else # All upcoming non option arguments are files to process
                files+=("$1")
                shift
            fi
            ;;
        esac
    done
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

function main() {
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

main "$@"
