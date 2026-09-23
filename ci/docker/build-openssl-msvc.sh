#!/usr/bin/env bash
# 目的: Linux 上で x86_64-pc-windows-msvc 向けの OpenSSL 静的ライブラリをビルドする
#       （openssl-src の vendored ビルドは Windows 版 perl + nmake を前提にしており、
#        Linux からのクロスでは Configure が失敗するため、その代替）
# 関連: ci/docker/inside-windows.sh から呼ばれる。結果は OPENSSL_DIR として openssl-sys に渡す
# 前提: cargo-xwin が XWIN_CACHE_DIR に CRT/SDK を展開済みであること。clang, llvm-ar が使えること
# 使い方: build-openssl-msvc.sh <openssl ソースディレクトリ> <インストール先>
set -euo pipefail
src=${1:?} prefix=${2:?}
xwin=${XWIN_CACHE_DIR:-/opt/xwin-cache}/xwin
stamp="$prefix/.built-from"
stamp_id="$src crt=static"
if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$stamp_id" ]; then
  echo "openssl already built: $prefix"
  exit 0
fi

work=$(mktemp -d)
cp -a "$src/." "$work/"
cd "$work"

# clang を MSVC ABI で動かし、Windows SDK / CRT ヘッダは xwin のものを使う。
# ビルド方式は unix 系（mingw64 設定）を借りるが、コンパイラは MSVC ターゲットなので
# 生成物は MSVC リンカで扱える COFF オブジェクト（静的ライブラリ）になる。
sysinc="-isystem $xwin/crt/include -isystem $xwin/sdk/include/ucrt -isystem $xwin/sdk/include/um -isystem $xwin/sdk/include/shared"
# wezterm は .cargo/config.toml で msvc ターゲットに +crt-static を指定しているので、静的 CRT (/MT 相当) に揃える
export CC="clang --target=x86_64-pc-windows-msvc -fms-runtime-lib=static -fms-compatibility -fms-extensions $sysinc"
export AR=llvm-ar RANLIB=llvm-ranlib RC=llvm-rc

perl ./Configure mingw64 \
  --prefix="$prefix" --libdir=lib \
  no-shared no-module no-tests no-apps no-docs no-asm no-comp no-zlib no-zlib-dynamic \
  no-ssl3 no-md2 no-rc5 no-weak-ssl-ciphers no-camellia no-idea no-seed no-capieng \
  -D_WIN32_WINNT=0x0601 -O2 -Wno-everything
make -j"$(nproc)" build_libs >/dev/null
make install_dev >/dev/null
# openssl-sys は MSVC ターゲットで libssl.lib / libcrypto.lib を探す
cp "$prefix/lib/libssl.a" "$prefix/lib/libssl.lib"
cp "$prefix/lib/libcrypto.a" "$prefix/lib/libcrypto.lib"
echo "$stamp_id" > "$stamp"
cd / && rm -rf "$work"
echo "openssl built: $prefix"
