#!/usr/bin/env bash
# 目的: Docker で配布用の wezterm バイナリを生成する
#       - Linux: headless（wezterm cli + wezterm-mux-server）を各ディストリ × amd64/arm64 で
#       - Windows: GUI 込み一式を cargo-xwin で x86_64-pc-windows-msvc 向けにクロスビルド（zip）
#         と、その zip から Inno Setup（wine 上）でインストーラーを作る
# 関連: ci/docker/Dockerfile.{linux,windows,innosetup}, ci/docker/inside-*.sh, ci/windows-installer.iss
# 前提: docker が使えること（sudo 不要・ホストの binfmt 変更不要）。成果物は dist/ に出力
#
# 使い方:
#   ci/docker/build.sh ubuntu22.04-amd64 debian12-arm64   # 個別指定
#   ci/docker/build.sh linux                              # Linux 全ターゲット
#   ci/docker/build.sh windows                            # Windows x64（zip + インストーラー）
#   ci/docker/build.sh all                                # 全部
#   ci/docker/build.sh list                               # ターゲット一覧
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"

declare -A BASES=(
  [ubuntu20.04]=ubuntu:20.04
  [ubuntu22.04]=ubuntu:22.04
  [ubuntu24.04]=ubuntu:24.04
  [debian12]=debian:12
  [debian13]=debian:13
)
LINUX_DISTROS=(ubuntu20.04 ubuntu22.04 ubuntu24.04 debian12)
ARCHES=(amd64 arm64)

all_linux() { for d in "${LINUX_DISTROS[@]}"; do for a in "${ARCHES[@]}"; do echo "$d-$a"; done; done; }

targets=()
for arg in "$@"; do
  case "$arg" in
    list) all_linux; echo windows-x64; echo windows-installer; exit 0 ;;
    linux) mapfile -t -O "${#targets[@]}" targets < <(all_linux) ;;
    windows) targets+=(windows-x64 windows-installer) ;;
    all) mapfile -t -O "${#targets[@]}" targets < <(all_linux); targets+=(windows-x64 windows-installer) ;;
    *) targets+=("$arg") ;;
  esac
done
if [ ${#targets[@]} -eq 0 ]; then
  echo "usage: $0 <target...|linux|windows|all|list>" >&2
  exit 1
fi

# ソースのスナップショット名（ci/deploy.sh の TAG_NAME と同じ形式: 日時-コミットID）
# jj 管理下では作業コピーのコミット（@）を使う。@ が空なら親（通常は patched）を使う
if [ -z "${TAG_NAME:-}" ]; then
  if command -v jj >/dev/null && [ -d .jj ]; then
    rev=@
    if [ "$(jj log --no-graph -r @ -T 'empty')" = true ]; then rev=@-; fi
    TAG_NAME=$(jj log --no-graph -r "$rev" -T 'committer.timestamp().format("%Y%m%d-%H%M%S") ++ "-" ++ commit_id.short(8)')
  else
    TAG_NAME=$(git -c core.abbrev=8 show -s --format=%cd-%h --date=format:%Y%m%d-%H%M%S)
  fi
fi
export TAG_NAME
OUT="$ROOT/dist/$TAG_NAME"
mkdir -p "$OUT" "$ROOT/tmp"

build_image() { # <image> <dockerfile> [build-args...]
  local image=$1 dockerfile=$2; shift 2
  local ctx
  ctx=$(mktemp -d "$ROOT/tmp/docker-ctx.XXXXXX")
  docker build -t "$image" "$@" -f "$dockerfile" "$ctx"
  rm -rf "$ctx"
}

common_run_args=(
  --rm
  -e TAG_NAME -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)"
  -v "$ROOT":/src:ro
  -v "$OUT":/out
  -v wezterm-cargo-registry:/opt/cargo/registry
  -v wezterm-cargo-git:/opt/cargo/git
)

failed=()
for t in "${targets[@]}"; do
  echo "=== $t ==="
  log="$ROOT/tmp/build-$t.log"
  case "$t" in
    windows-x64)
      build_image wezterm-build:windows ci/docker/Dockerfile.windows
      cmd=(docker run "${common_run_args[@]}"
        -v wezterm-target-windows:/build/target
        -v wezterm-xwin-cache:/opt/xwin-cache
        wezterm-build:windows bash /src/ci/docker/inside-windows.sh)
      ;;
    windows-installer)
      build_image wezterm-build:innosetup ci/docker/Dockerfile.innosetup
      cmd=(docker run --rm -e TAG_NAME -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)"
        -v "$ROOT":/src:ro -v "$OUT":/out
        wezterm-build:innosetup bash /src/ci/docker/inside-innosetup.sh)
      ;;
    *-amd64|*-arm64)
      distro=${t%-*} arch=${t##*-}
      base=${BASES[$distro]:-}
      [ -n "$base" ] || { echo "unknown distro: $distro" >&2; exit 1; }
      build_image "wezterm-build:$distro" ci/docker/Dockerfile.linux --build-arg BASE="$base"
      # glibc やシステムライブラリが違うのでディストリ間で target/ は共有しない
      cmd=(docker run "${common_run_args[@]}"
        -e DISTRO="$distro" -e ARCH="$arch"
        -v "wezterm-target-$distro":/build/target
        "wezterm-build:$distro" bash /src/ci/docker/inside-linux.sh)
      ;;
    *) echo "unknown target: $t" >&2; exit 1 ;;
  esac
  if "${cmd[@]}" >"$log" 2>&1; then
    tail -1 "$log"
  else
    echo "FAILED: $t (log: $log)" >&2
    tail -20 "$log" >&2
    failed+=("$t")
  fi
done

(cd "$OUT" && sha256sum -- *.tar.xz *.zip *.exe 2>/dev/null > SHA256SUMS || true)
echo "artifacts: $OUT"
ls -la "$OUT"
if [ ${#failed[@]} -gt 0 ]; then
  echo "failed targets: ${failed[*]}" >&2
  exit 1
fi
