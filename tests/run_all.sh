#!/usr/bin/env sh
set -eu

mod_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
host_root=$(CDPATH= cd -- "$mod_dir/../.." && pwd)

cd "$host_root"
for test_file in "$mod_dir"/tests/*_test.lua; do
  luajit "$test_file"
done
