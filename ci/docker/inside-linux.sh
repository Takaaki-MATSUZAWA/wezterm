#!/usr/bin/env bash
# 目的: Linux ビルドコンテナ内で headless wezterm をビルドして tar.xz にまとめる
# 関連: ci/docker/build.sh から呼ばれる
# 前提: /src にリポジトリ（読み取り専用）、/out に成果物出力先、/build/target にキャッシュ volume
#       環境変数 TAG_NAME, DISTRO, ARCH(amd64|arm64), HOST_UID, HOST_GID
set -euo pipefail

case "$ARCH" in
  amd64) triple=x86_64-unknown-linux-gnu; strip=strip ;;
  arm64) triple=aarch64-unknown-linux-gnu; strip=aarch64-linux-gnu-strip ;;
  *) echo "unknown ARCH=$ARCH" >&2; exit 1 ;;
esac

bash /src/ci/docker/copy-src.sh /build/src
cd /build/src

export CARGO_TARGET_DIR=/build/target
# .tag の中身はキャッシュ判定に使われないことがあるので、バージョン埋め込みクレートだけ作り直す
cargo clean --release --target "$triple" -p wezterm-version
cargo build --release --locked --target "$triple" -p wezterm -p wezterm-mux-server

name="wezterm-headless-${TAG_NAME}.${DISTRO}.${ARCH}"
stage="/build/stage/$name"
rm -rf /build/stage && mkdir -p "$stage"
cp "$CARGO_TARGET_DIR/$triple/release/wezterm" "$CARGO_TARGET_DIR/$triple/release/wezterm-mux-server" "$stage/"
"$strip" "$stage/wezterm" "$stage/wezterm-mux-server"
cp LICENSE.md "$stage/"
cp ci/docker/install-headless.sh "$stage/install.sh"
cat > "$stage/BUILDINFO" <<INFO
tag: ${TAG_NAME}
distro: ${DISTRO}
arch: ${ARCH}
target: ${triple}
glibc: $(ldd --version | head -1)
INFO
tar -C /build/stage -cJf "/out/$name.tar.xz" "$name"
chown "${HOST_UID}:${HOST_GID}" "/out/$name.tar.xz"
echo "built: /out/$name.tar.xz"
