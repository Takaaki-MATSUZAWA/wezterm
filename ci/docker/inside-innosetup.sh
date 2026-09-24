#!/usr/bin/env bash
# 目的: Windows 版 zip の中身から本家の ci/windows-installer.iss が期待する構成を組み、
#       wine 上の ISCC.exe でインストーラー（WezTerm-<TAG>-setup.exe）を作る
# 関連: ci/docker/build.sh（windows-installer ターゲット）, ci/docker/Dockerfile.innosetup
# 前提: /src にリポジトリ（読み取り専用）、/out に WezTerm-windows-<TAG>.zip があること
#       環境変数 TAG_NAME, HOST_UID, HOST_GID
set -euo pipefail
zip="/out/WezTerm-windows-${TAG_NAME}.zip"
[ -f "$zip" ] || { echo "missing $zip （先に windows-x64 をビルドしてください）" >&2; exit 1; }

# .iss は "..\target\release\*" と "..\assets\windows\terminal.ico" を参照し、出力先は ".."
work=/build/iss
rm -rf "$work" /build/unzip && mkdir -p "$work/ci" "$work/assets/windows" "$work/target/release" /build/unzip
cp /src/ci/windows-installer.iss "$work/ci/"
cp /src/assets/windows/terminal.ico "$work/assets/windows/"
unzip -q "$zip" -d /build/unzip
cp -a /build/unzip/*/. "$work/target/release/"

name="WezTerm-${TAG_NAME}-setup"
cd "$work"
xvfb-run -a wine 'C:\InnoSetup\ISCC.exe' /Q "/DMyAppVersion=${TAG_NAME}" "/F${name}" 'Z:\build\iss\ci\windows-installer.iss'
wineserver -w
cp "$work/$name.exe" /out/
chown "${HOST_UID}:${HOST_GID}" "/out/$name.exe"
echo "built: /out/$name.exe"
