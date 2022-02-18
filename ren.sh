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
    -n, --dry-run
        Print names of files to be renamed, but don't rename.

    -h, --help
        Print synopsis, options and examples.

    -v, --version
        Print version number.

Examples:
    ren 's/.*/clipart-[C].png/' *.png
    ren 's/(.*)\.(.*)/\$1-[C:5].\$2/' *.*

Full documentation at: https://github.com/linogefly/ren
EOF
}

function show_version() {
    echo "$__version"
}

function show_invalid_perlexpr_argument_error_message() {
    cat <<EOF
Invalid perlexpr argument. A Perl regular expression with substitute operator is expected. The basic form of the operator is 's/pattern/replacement/[gi]'.
EOF
}

# $1: replacement expression
function show_invalid_replacement_expression_argument_error_message() {
    cat <<EOF
Invalid perlexpr argument. Pattern expression '$1' has incorrect usage of square brackets '[' and ']'. Square brackets are used to define a counter placeholder. If square brackets are needed as part of a filename they need to be escaped, like '\[' and '\]'.
EOF
}

# $1: counter placeholder
function show_invalid_counter_placeholder_error_message() {
    cat <<EOF
Counter placeholder '$1' has invalid format. Allowed formats are:
  [C]      a counter with default parameters.
  [CN]     a counter that starts at N.
  [C+S]    a counter with the step of S.
  [C:W]    a counter that has digits width of W.
  [C+S:W]  a counter with the step of S and digits width of W.
EOF
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
            echo >&2 "Unknown option $1."
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
    {
        read -r replacementExpression
        read -r replacementExpressionIndex
        read -r replacementExpressionLength
    } <<<$(get_replacement_expression "$1")
    local replacementExpressionResult="$replacementExpression"
    local placeholders=$(get_counter_placeholders "$1")

    while IFS= read -r placeholder; do
        # Find "start at" parameter in counter placeholder
        local startAt=$(echo "$placeholder" | grep -Pio '(?<=C)\d*')
        if [ -z $startAt ]; then
            startAt=1
        fi

        # Find "step by" parameter in counter placeholder
        local stepBy=$(echo "$placeholder" | grep -Pio '(?<=\+)\d*')
        if [ -z $stepBy ]; then
            stepBy=1
        fi

        # Find "digits width" parameter in counter placeholder
        local digitsWidth=$(echo "$placeholder" | grep -Pio '(?<=\:)\d*')
        if [ -z $digitsWidth ]; then
            digitsWidth=1
        fi

        # Calculate counter value and format it based on digits width
        printf -v counter "%0${digitsWidth}d" $(($startAt + $2 * $stepBy))

        # Replace counter placeholder with counter value
        replacementExpressionResult="${replacementExpressionResult/"$placeholder"/"$counter"}"

    done <<<"$placeholders"

    # Return "perlexpr" that has counter placeholders replaced with counter values
    echo "${1:0:replacementExpressionIndex}${replacementExpressionResult}${1:replacementExpressionIndex+replacementExpressionLength}"
}

# $1: perlexpr
# return:
#   line 1: replacement expression
#   line 2: index (starting position)
#   line 3: length
function get_replacement_expression() {
    # Get replacement part from a Perl substitute regular expression operator,
    # which has the basic form of 's/pattern/replacement/[gi]'.

    local regEx='s/[^/]*/\K[^/]*'
    local replacementExpression=$(echo "$perlexpr" | grep -Pio "$regEx")
    local replacementExpressionWithIndex=$(echo "$1" | grep -Piob "$regEx")
    local index=$(cut -d : -f 1 <<<"$replacementExpressionWithIndex")

    echo "$replacementExpression"
    echo "$index"
    echo "${#replacementExpression}"
}

# $1: perlexpr
function get_counter_placeholders() {
    {
        read -r replacementExpression
    } <<<$(get_replacement_expression "$1")

    echo "$replacementExpression" | grep -Pio '(?<!\\)\[[C].*?(?<!\\)\]'
}

# $1: perlexpr
function validate_replacement_expression() {
    { read -r replacementExpression; } <<<$(get_replacement_expression "$1")

    if [ -z "$replacementExpression" ]; then
        show_invalid_perlexpr_argument_error_message >&2
        exit 2
    fi

    # First remove all counter placeholders
    local replacementExpressionWithoutPlaceholders=$(echo $replacementExpression | perl -pe 's/(?<!\\)\[[C].*?(?<!\\)\]//gi')

    # Then find not escaped square brackets
    local notEscapedSquareBrackets=$(echo "$replacementExpressionWithoutPlaceholders" | grep -Pio '((?<!\\)\[)|((?<!\\)\])')

    # If there are any, then the replacement expression is no valid
    if [ -n "$notEscapedSquareBrackets" ]; then
        show_invalid_replacement_expression_argument_error_message "$1" >&2
        exit 2
    fi
}

# $1: list with counter placeholders
function validate_counter_placeholders() {
    while IFS= read -r placeholder; do
        validate_counter_placeholder "$placeholder"
    done <<<"$1"
}

# $1: one counter placeholders
function validate_counter_placeholder() {
    local validFormats=(
        '^\[C\d*\]$'            # [C] [C10]
        '^\[C\d*(\+|\:)+\d+\]$' # [C+5] [C:3] [C10+5] [C10:3]
        '^\[C\d*\++\d+:+\d+\]$' # [C+5:3] [C10+5:3]
    )
    local isValid=

    for i in "${!validFormats[@]}"; do
        local validFormat=${validFormats[$i]}
        local match=$(echo "$1" | grep -Pio "$validFormat")

        if [ -n "$match" ]; then
            isValid='true'
        fi
    done

    if [ -z $isValid ]; then
        show_invalid_counter_placeholder_error_message "$1" >&2
        exit 2
    fi
}

function main() {
    # Default settings
    local perlexpr=''
    local files=()
    local renameOptions=()

    parse_args "$@"
    validate_replacement_expression "$perlexpr"

    local placeholders=$(get_counter_placeholders "$perlexpr")

    # If there are no counter placeholders in 'perlexpr' argument then we just pass
    # 'perlexpr' argument to 'rename' command as is, without making any modifications to it.
    if [ -z "$placeholders" ]; then
        rename "${renameOptions[@]}" "$perlexpr" "${files[@]}"
        exit 0
    fi

    validate_counter_placeholders "$placeholders"

    for i in ${!files[@]}; do
        local file=${files[$i]}
        local renamePerlexpr="$(inject_counter "$perlexpr" $i)"

        rename "${renameOptions[@]}" "$renamePerlexpr" "$file"
    done
}

main "$@"
