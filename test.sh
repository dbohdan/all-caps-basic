#!/bin/sh
set -e
set -o pipefail
set -u

run="$(dirname "$0")/run.sh"
actual_output_file="$(mktemp)"

# Delete temporary files on exit.
trap "rm -f \"$actual_output_file\"" 0 1 2 3 15

for file in test/*.bas; do
    prefix="test/$(basename "$file" .bas)"
    correct_output_file="$prefix.output"
    error_output_file="$prefix.error"
    error=0
    if [ -e "$correct_output_file" ]; then
        "$run" "$prefix.bas" >"$actual_output_file" || true
        diff "$correct_output_file" "$actual_output_file" || error=1
    elif [ -e "$error_output_file" ]; then
        "$run" "$prefix.bas" | tail -n 1 >"$actual_output_file" || true
        diff "$error_output_file" "$actual_output_file" || error=1
    fi
    if [ "$error" -gt 0 ]; then
        echo "in $prefix.bas"
        echo ''
    fi
done
