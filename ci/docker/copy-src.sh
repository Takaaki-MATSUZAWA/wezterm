#!/usr/bin/env bash
# 目的: 読み取り専用でマウントされた /src から、ビルドに必要なソースだけを作業ディレクトリへ複製する
# 関連: ci/docker/inside-*.sh から呼ばれる
# 前提: 引数に複製先ディレクトリ。ビルド成果物・VCS メタデータ・ローカル専用ファイルは除外する
set -euo pipefail
dest=${1:?}
rm -rf "$dest" && mkdir -p "$dest"
tar -C /src \
  --exclude=./target --exclude=./dist --exclude=./tmp --exclude=./scratch \
  --exclude=./.jj --exclude=./.git --exclude=./reports --exclude=./.claude \
  -cf - . | tar -xf - -C "$dest"
# .git を持ち込まないので、バージョン文字列は wezterm-version/build.rs が読む .tag で与える
if [ -n "${TAG_NAME:-}" ]; then
  echo "$TAG_NAME" > "$dest/.tag"
fi
