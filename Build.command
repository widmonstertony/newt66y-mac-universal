#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
"$SCRIPT_DIR/build.sh"
print
read -k 1 "?构建完成。按任意键关闭…"
