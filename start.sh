#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting..."
cd "$dir"
dart --enable-vm-service run