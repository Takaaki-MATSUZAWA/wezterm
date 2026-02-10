# Patched Fork

This is a personal fork with the following bug-fix patches applied on the `patched` branch:

| Branch | Issue/PR | Description |
|--------|----------|-------------|
| `fix/5117-pane-size-corruption` | [#5117](https://github.com/wezterm/wezterm/issues/5117) | Pane size corruption on mux client detach |
| `fix/5832-user-vars-mux-sync` | [#5832](https://github.com/wezterm/wezterm/issues/5832) | user_vars not synced on mux reconnect |
| `fix/2056-ime-selected-string` | [#2056](https://github.com/wezterm/wezterm/pull/2056) | IME pre-edit text highlight (from kumattau) |
| `strackeror/sequence-pane-focus-events` | [#7399](https://github.com/wezterm/wezterm/pull/7399) | Focus event infinite loop fix (from Strackeror) |

## Branch structure

- `main` — tracks upstream `wezterm/wezterm`
- `patched` — daily-use branch (all fix branches merged)
- `fix/*` — individual fix branches

## Building

```bash
git checkout patched
cargo build --release
```

Pre-built binaries (Windows + Ubuntu 22.04) can be generated via Actions → "Build patched" → Run workflow.

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
* There is a [Matrix room via Element.io](https://app.element.io/#/room/#wezterm:matrix.org)
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
