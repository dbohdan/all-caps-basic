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
    if [ -e "$correct_output_file" ]; then
        "$run" "$prefix.bas" >"$actual_output_file"
        diff "$actual_output_file" "$correct_output_file"
    fi
done
