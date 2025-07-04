#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting from $dir..."
cd "$dir"
dart --enable-vm-service run
code=$?
echo "The Dart service exited with code $code."

if [ $code -eq 249 ]; then
    echo "Restarting..."
    exec "$0" "$@"
    exit $code
fi