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
# キャッシュ volume に残った clang-cl の symlink が古い clang を指していると cargo-xwin が失敗するので消す
rm -f "${XWIN_CACHE_DIR:-/opt/xwin-cache}/clang-cl"

# openssl-src の vendored ビルドは Linux から MSVC 向けに Configure できないので、
# 同じバージョンの OpenSSL ソースを別途ビルドして openssl-sys に渡す。
# （xwin の CRT/SDK が必要なので、先に cargo xwin に取得させる）
cargo fetch --locked >/dev/null
cargo xwin env --target "$triple" >/dev/null
ossl_src=$(ls -d /opt/cargo/registry/src/*/openssl-src-*/openssl | sort -V | tail -1)
ossl_prefix="$CARGO_TARGET_DIR/openssl-msvc"
before=$(cat "$ossl_prefix/.built-from" 2>/dev/null || true)
bash /src/ci/docker/build-openssl-msvc.sh "$ossl_src" "$ossl_prefix"
if [ "$before" != "$(cat "$ossl_prefix/.built-from")" ]; then
  # 静的ライブラリは依存 crate の rlib に取り込まれるので、OpenSSL を作り直したらそれらも作り直す
  cargo clean --release --target "$triple" -p openssl-sys -p libssh2-sys -p libssh-rs-sys -p openssl
fi
# ホスト向け（build script の依存など）の openssl-sys に影響しないよう、ターゲット名付きの変数で渡す
export X86_64_PC_WINDOWS_MSVC_OPENSSL_NO_VENDOR=1 \
  X86_64_PC_WINDOWS_MSVC_OPENSSL_STATIC=1 \
  X86_64_PC_WINDOWS_MSVC_OPENSSL_DIR="$CARGO_TARGET_DIR/openssl-msvc" \
  X86_64_PC_WINDOWS_MSVC_OPENSSL_LIBS=libssl:libcrypto
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
