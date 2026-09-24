# Patched Fork

This is a personal fork (based on [yosagi/wezterm](https://github.com/yosagi/wezterm))
with the following bug-fix patches applied on top of upstream `main` in the `patched` branch:

| Branch | Issue/PR | Description |
|--------|----------|-------------|
| `fix/mux-subscriber-leak` | - | `wezterm-mux-server` leaked ~130KB per client connection (eg: every `wezterm cli list`) on an idle mux |
| `fix/5117-pane-size-corruption` | [#5117](https://github.com/wezterm/wezterm/issues/5117) | Pane size corruption on mux client detach |
| `fix/5832-user-vars-mux-sync` | [#5832](https://github.com/wezterm/wezterm/issues/5832) | user_vars not synced on mux reconnect |
| `fix/focus-reconcile-storm` | [#4390](https://github.com/wezterm/wezterm/issues/4390) | Focus event storm / infinite loop fix (from fculpo, [PR #7763](https://github.com/wezterm/wezterm/pull/7763)) |
| `fix/2056-ime-selected-string` | [#2056](https://github.com/wezterm/wezterm/pull/2056) | IME pre-edit text highlight (from kumattau) |
| `fix/make-all-stale-unbounded-cache` | [#7363](https://github.com/wezterm/wezterm/issues/7363) | Unbounded LruCache memory leak fix ([PR #7704](https://github.com/wezterm/wezterm/pull/7704)) |

## Branch structure

- `patched` — daily-use branch (all fix branches merged on top of upstream `main`)
- `fix/*` — individual fix branches, rebased on upstream `main`

## Building

```bash
git checkout patched
cargo build --release
```

### Distribution binaries with Docker

`ci/docker/build.sh` builds release artifacts in containers (no root, no binfmt/QEMU needed):

| Target | Output |
|--------|--------|
| `ubuntu20.04-{amd64,arm64}`, `ubuntu22.04-*`, `ubuntu24.04-*`, `debian12-*` | headless `wezterm` (cli) + `wezterm-mux-server` as `.tar.xz` (arm64 is cross compiled) |
| `windows-x64` | full WezTerm zip (GUI included), cross compiled with [cargo-xwin](https://github.com/rust-cross/cargo-xwin) |
| `windows-installer` | `WezTerm-<tag>-setup.exe` built from that zip with the upstream `ci/windows-installer.iss` ([Inno Setup](https://jrsoftware.org/isinfo.php) running under wine) |

```bash
ci/docker/build.sh list      # show targets
ci/docker/build.sh linux     # all Linux targets
ci/docker/build.sh windows   # Windows x64 zip + installer
ci/docker/build.sh all
```

Artifacts are written to `dist/<tag>/`.  The Windows build downloads the
Microsoft CRT and Windows SDK via cargo-xwin, which implies accepting the
Microsoft license terms.

The installer uses the same AppId as the upstream installer, so it upgrades
an existing official WezTerm installation in place.

---

# Wez's Terminal

<img height="128" alt="WezTerm Icon" src="https://raw.githubusercontent.com/wezterm/wezterm/main/assets/icon/wezterm-icon.svg" align="left"> *A GPU-accelerated cross-platform terminal emulator and multiplexer written by <a href="https://github.com/wez">@wez</a> and implemented in <a href="https://www.rust-lang.org/">Rust</a>*

User facing docs and guide at: https://wezterm.org/

![Screenshot](docs/screenshots/two.png)

*Screenshot of wezterm on macOS, running vim*

## Installation

https://wezterm.org/installation

## Getting help

This is a spare time project, so please bear with me.  There are a couple of channels for support:

* You can use the [GitHub issue tracker](https://github.com/wezterm/wezterm/issues) to see if someone else has a similar issue, or to file a new one.
* Start or join a thread in our [GitHub Discussions](https://github.com/wezterm/wezterm/discussions); if you have general
  questions or want to chat with other wezterm users, you're welcome here!
* There is a [Matrix room via Element.io](https://matrix.to/#/#wezterm:matrix.org)
  for (potentially!) real time discussions.

The GitHub Discussions and Element/Gitter rooms are better suited for questions
than bug reports, but don't be afraid to use whichever you are most comfortable
using and we'll work it out.

## Supporting the Project

If you use and like WezTerm, please consider sponsoring it: your support helps
to cover the fees required to maintain the project and to validate the time
spent working on it!

[Read more about sponsoring](https://wezterm.org/sponsor.html).

* [![Sponsor WezTerm](https://img.shields.io/github/sponsors/wez?label=Sponsor%20WezTerm&logo=github&style=for-the-badge)](https://github.com/sponsors/wez)
* [Patreon](https://patreon.com/WezFurlong)
* [Ko-Fi](https://ko-fi.com/wezfurlong)
* [Liberapay](https://liberapay.com/wez)
