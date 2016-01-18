#!/bin/sh
set -e
set -o pipefail
set -u

# Settings.
awk="nawk"
compiler_dir="$(dirname "$0")"
input_file="$1"
# $verbose & 1 -- show lexer output
# $verbose & 2 -- show parser output
# $verbose & 4 -- show codegen output
verbose=7

# Variables for internal use.
exit=0
temp_bin_file="$(mktemp)"
temp_c_file="$(mktemp).c"
temp_lex_file="$(mktemp)"
temp_parse_file="$(mktemp)"

# Delete temporary files on exit.
trap "rm -f \"$temp_bin_file\" \"$temp_c_file\" \"$temp_lex_file\" \
        \"$temp_parse_file\"" 0 1 2 3 15

# Lex.
$awk -f "$compiler_dir/library.awk" -f "$compiler_dir/lexer.awk" \
        <"$input_file" >"$temp_lex_file" || exit=1
if expr "$verbose" % 2 >/dev/null; then
    echo '### Lexer output ###'
    echo ''
    cat "$temp_lex_file"
    echo '### End lexer output ###'
    echo ''
fi
expr "$exit" >/dev/null && exit 1

# Parse.
$awk -f "$compiler_dir/parser.awk" \
        <"$temp_lex_file" >"$temp_parse_file" || exit=1
if expr "$verbose" / 2 % 2 >/dev/null; then
    echo '### Parser output ###'
    echo ''
    cat "$temp_parse_file"
    echo '### End parser output ###'
    echo ''
fi
expr "$exit" >/dev/null && exit 1

# Generate code.
$awk -f "$compiler_dir/library.awk" -f "$compiler_dir/codegen.awk" \
        <"$temp_parse_file" >"$temp_c_file" || exit=1
if expr "$verbose" / 4 % 2 >/dev/null; then
    echo '### C code ###'
    echo ''
    cat "$temp_c_file"
    echo '### end C code ###'
    echo ''
fi
expr "$exit" >/dev/null && exit 1

# Compile and run.
gcc "$temp_c_file" -o "$temp_bin_file"
"$temp_bin_file"