#!/usr/bin/env bash
# 目的: headless wezterm（wezterm cli + wezterm-mux-server）を配置する
# 使い方: sudo ./install.sh [PREFIX]   （既定の PREFIX は /usr/local）
# 注意: 配置後、稼働中の wezterm-mux-server を再起動しないと新しいバイナリは使われない
set -euo pipefail
PREFIX=${1:-/usr/local}
here=$(cd "$(dirname "$0")" && pwd)
install -d "$PREFIX/bin"
install -m 755 "$here/wezterm" "$here/wezterm-mux-server" "$PREFIX/bin/"
echo "installed to $PREFIX/bin"
"$PREFIX/bin/wezterm" --version
