#!/usr/bin/env bash
# 目的: Windows クロスビルドコンテナ内で wezterm 一式をビルドして zip にまとめる
#       （ci/deploy.sh の Windows 向け zip と同じ構成）
# 関連: ci/docker/build.sh から呼ばれる
# 前提: /src にリポジトリ（読み取り専用）、/out に成果物出力先、/build/target にキャッシュ volume
#       環境変数 TAG_NAME, HOST_UID, HOST_GID
set -euo pipefail
triple=x86_64-pc-windows-msvc

bash /src/ci/docker/copy-src.sh /build/src
cd /build/src

export CARGO_TARGET_DIR=/build/target
cargo clean --release --target "$triple" -p wezterm-version
cargo xwin build --release --locked --target "$triple" \
  -p wezterm -p wezterm-gui -p wezterm-mux-server -p strip-ansi-escapes

rel="$CARGO_TARGET_DIR/$triple/release"
name="WezTerm-windows-${TAG_NAME}"
stage="/build/stage/$name"
rm -rf /build/stage && mkdir -p "$stage/mesa"
cp "$rel/wezterm.exe" "$rel/wezterm-gui.exe" "$rel/wezterm-mux-server.exe" "$rel/strip-ansi-escapes.exe" \
  assets/windows/conhost/conpty.dll assets/windows/conhost/OpenConsole.exe \
  assets/windows/angle/libEGL.dll assets/windows/angle/libGLESv2.dll \
  LICENSE.md "$stage/"
cp assets/windows/mesa/opengl32.dll "$stage/mesa/"
cp "$rel/wezterm.pdb" "$stage/" 2>/dev/null || true
(cd /build/stage && zip -qr "/out/$name.zip" "$name")
chown "${HOST_UID}:${HOST_GID}" "/out/$name.zip"
echo "built: /out/$name.zip"
