#!/bin/sh
set -e
set -o pipefail
set -u

help() {
    echo "Usage: $0 [-lpcv] filename.bas"
}

# Settings.
awk="nawk"
compiler_dir="$(dirname "$0")"
# $verbose & 1 -- show lexer output.
# $verbose & 2 -- show parser output.
# $verbose & 4 -- show codegen output.
verbose=0

params="$(getopt lpcv $*)"
set -- $params
while [ $# -ne 1 ]; do
    case "$1" in
        -l)
            verbose="$(expr "$verbose" + 1)"
            shift
            ;;
        -p)
            verbose="$(expr "$verbose" + 2)"
            shift
            ;;
        -c)
            verbose="$(expr "$verbose" + 4)"
            shift
            ;;
        -v)
            verbose=7
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            help
            exit 77
            ;;
    esac
done

# Variables for internal use.
exit=0
if [ "$#" -eq "0" ] || [ ! -e "$1" ]; then
    help
    exit 99
fi
input_file="$1"
temp_bin_file="$(mktemp)"
temp_c_file="$(mktemp "$(dirname "$temp_bin_file")"/tmp.XXXXXXXXXX.c)"
temp_lex_file="$(mktemp)"
temp_parse_file="$(mktemp)"

# Delete temporary files on exit.
trap "rm -f \"$temp_bin_file\" \"$temp_c_file\" \"$temp_lex_file\" \
        \"$temp_parse_file\"" 0 1 2 3 15

# Lex.
"$awk" -f "$compiler_dir/library.awk" -f "$compiler_dir/lexer.awk" \
        "$compiler_dir/lib/prelude.bas" >"$temp_lex_file" || exit=1
while [ $# -gt 0 ]; do
    "$awk" -f "$compiler_dir/library.awk" -f "$compiler_dir/lexer.awk" \
            "$1" >>"$temp_lex_file" || exit=1
    shift
done
if expr "$verbose" % 2 >/dev/null; then
    echo '### Lexer output ###'
    echo ''
    cat "$temp_lex_file"
    echo '### End lexer output ###'
    echo ''
fi
if [ "$exit" -gt 0 ]; then
    cat "$temp_lex_file"
    exit 1
fi

# Parse.
"$awk" -f "$compiler_dir/library.awk" -f "$compiler_dir/parser.awk" \
        <"$temp_lex_file" >"$temp_parse_file" || exit=1
if expr "$verbose" / 2 % 2 >/dev/null; then
    echo '### Parser output ###'
    echo ''
    cat "$temp_parse_file"
    echo '### End parser output ###'
    echo ''
fi
if [ "$exit" -gt 0 ]; then
    cat "$temp_parse_file"
    exit 2
fi

# Generate code.
"$awk" -f "$compiler_dir/library.awk" -f "$compiler_dir/codegen.awk" \
        <"$temp_parse_file" >"$temp_c_file" || exit=1
if expr "$verbose" / 4 % 2 >/dev/null; then
    echo '### C code ###'
    echo ''
    cat "$temp_c_file"
    echo '### end C code ###'
    echo ''
fi
if [ "$exit" -gt 0 ]; then
    cat "$temp_c_file"
    exit 3
fi

# Compile and run.
gcc \
        -I"$compiler_dir/deps/sds" \
        -I"$compiler_dir/include" \
        -L"$compiler_dir/lib" \
        "$temp_c_file" \
        "$compiler_dir/lib/cprelude.c" \
        "$compiler_dir/deps/sds/sds.c" \
        -o "$temp_bin_file" \
        -lgc || exit 4
"$temp_bin_file" || exit 5
