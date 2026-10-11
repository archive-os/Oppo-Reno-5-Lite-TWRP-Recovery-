#!/bin/sh
set -eu
if [ "$#" -gt 1 ]; then
  echo 'Usage: sh tools/open-mtk-gui.sh [mtkclient-directory]' >&2
  exit 2
fi
if [ "$#" -eq 1 ]; then
  target=$1
else
  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  target="$script_dir/../mtkclient"
fi
if [ ! -f "$target/mtk_gui.py" ] || [ ! -x "$target/.venv/bin/python" ]; then
  echo 'MTKClient installation not found. Complete step 2 in README.md or provide the installed directory path.' >&2
  exit 1
fi
cd -- "$target"
exec ./.venv/bin/python mtk_gui.py
