# Contributing

This is a mise tool plugin using the vfox-style Lua hooks architecture.

## Setting up a development environment

Install the development tools declared in `mise.toml`:

```bash
mise install
```

Install the pre-commit hooks (optional but recommended):

```bash
hk install
```

## Local testing

Link your working copy as the plugin implementation:

```bash
mise plugin link --force eclipse-jdtls .
```

Then:

```bash
mise run test      # install, assert layout, smoke test
mise run lint      # hk check
mise run lint-fix  # hk fix, auto-fixes what it can
mise run format    # stylua only
mise run ci        # lint + test
```

### Testing in a container

Installing repeatedly pollutes your real mise setup, so it is worth doing this
work in a throwaway container. Whether you do or not, turn these on:

```bash
mise settings set always_keep_download true
mise settings set always_keep_install true
```

- `always_keep_download` reuses the archive between runs. Milestone builds are
  50–180 MB, so this is the difference between an instant iteration and a
  multi-minute one.
- `always_keep_install` leaves the partially-installed directory in place when
  a hook throws, so you can inspect what mise actually extracted.

`MISE_DEBUG=1` in front of any command shows each hook invocation and every
HTTP request the plugin makes — the fastest way to see what your hooks did.

## Code quality

Linting and pre-commit hooks are managed by [hk](https://hk.jdx.dev), configured
in `hk.pkl`:

- **Formatting**: `stylua` (`stylua.toml`)
- **Static analysis**: `lua-language-server --check` (`.luarc.json`)
- **GitHub Actions linting**: `actionlint`

```bash
hk check   # same as mise run lint
hk fix     # auto-fix
```

## How the plugin works

Upstream publishes prebuilt jdtls binaries only as milestone builds. Each
milestone directory contains a timestamped archive whose name cannot be derived
from the version alone:

```
https://download.eclipse.org/jdtls/milestones/1.60.0/
    jdt-language-server-1.60.0-202606262232.tar.gz
    jdt-language-server-1.60.0-202606262232.tar.gz.sha256
    latest.txt
    repository/
```

`latest.txt` holds just that filename, which is how the plugin resolves the
archive without scraping the directory index. The `.sha256` file holds only the
bare hash with no filename column. Both need trailing whitespace trimmed.

Hook responsibilities:

| Hook | Does |
| --- | --- |
| `hooks/available.lua` | Lists 1.x tags from the GitHub tags API, minus known versions with no milestone build, plus the current snapshot |
| `hooks/pre_install.lua` | Resolves the archive name via `latest.txt`, fetches the checksum, returns both to mise |
| `hooks/env_keys.lua` | Adds `bin/` to `PATH` |

There is no `post_install.lua`. Both milestone and snapshot archives extract to
a flat layout that already matches what jdtls expects, so nothing needs
rearranging. Hooks are optional — mise simply does not call one that is absent.

`PreInstall` does **not** download anything. It returns a descriptor
(`{version, url, sha256}`) and mise performs the download, checksum
verification, and extraction. The only HTTP requests the plugin makes itself are
for `latest.txt` and the checksum.

## The two checksums

Confusingly, the plugin supplies a checksum in two places for two unrelated
purposes:

| Field | Purpose | Applies to |
| --- | --- | --- |
| `PreInstall` → `sha256` | Integrity: mise verifies the downloaded archive against it | every version |
| `Available` → `checksum` | Identity: detects that a rolling version now points at different bytes | `rolling` entries only |

Milestone versions are immutable, so the version string alone identifies the
build and no `Available` checksum is needed. Snapshots reuse the same version
string across rebuilds, so mise needs a second token to tell builds apart.

**These two values must match.** mise stores `PreInstall`'s `sha256` at install
time and later compares it against `Available`'s `checksum` to decide whether a
rolling version is stale (`src/backend/vfox.rs`, `src/backend/mod.rs` —
`is_rolling_version_outdated`). The comparison is plain string equality, so if
the two hooks report different values the snapshot is considered outdated on
every check and reinstalls endlessly. Both therefore fetch the same
`.sha256` file.

Returning no `sha256` from `PreInstall` has the same effect: nothing is stored,
and an absent stored checksum is treated as outdated.

## Why the snapshot version is "latest-snapshot"

`Available` publishes the rolling channel as the literal string
`latest-snapshot`, not as the resolved build it currently points at
(`1.61.0-snapshot`). That is deliberate and load-bearing:

- mise looks a rolling version up by the **requested** string
  (`outdated_info.rs` passes `tool_version.request.version()`), so the
  `Available` entry has to use that same string or the lookup misses and the
  version is silently never considered outdated.
- The stored checksum is written under the **resolved** version, so `PreInstall`
  must echo `ctx.version` back unchanged. Resolving `latest-snapshot` to a
  concrete build makes the write key and the read key disagree.

In short: requested version, `Available` entry, and `PreInstall`'s returned
version must all be the same literal. This is the same shape other rolling
channels use, e.g. zig's `master`.

A side effect worth knowing: `latest-snapshot` is not valid semver, so mise
does not classify it as a prerelease. It is therefore always listed by
`ls-remote` regardless of the `prereleases` setting, and it can never win
`@latest` resolution — which is what keeps `@latest` meaning "newest
milestone".

## Versions with no milestone build

Not every Git tag has a milestone build. `hooks/available.lua` carries a
`NO_MILESTONE` table of known gaps so they never appear in `mise ls-remote`.

That table will go stale as upstream skips future releases, and `Available` is
advisory anyway — nothing stops a user requesting an excluded version
explicitly. So `PreInstall` also treats a 404 on `latest.txt` as "no milestone
build" and fails with an explicit error. Keep both.

See [docs/milestone-coverage.md](./docs/milestone-coverage.md) for the current
gap list and how to regenerate it.

## Working in Lua

If you are new to Lua, these are the ones that actually bite. All are stock
Lua, not mise additions:

- **Tables are 1-indexed.** The last element is `t[#t]`, not `t[#t - 1]`.
  `table.concat` starts at index 1 and silently ignores a value at index 0.
- **Undeclared variables are globals.** Always write `local`. `hk check` catches
  these.
- **Patterns are not regex.** `%` is the escape character, not `\` — a literal
  dot is `%.`, and an unescaped `.` matches any character *including* newlines.
  A trailing `-` means "zero or more, lazily", so `string.find(s, "milestone-")`
  matches the string `"mileston"`. Pass `true` as the fourth argument for a
  plain-text search, or use `strings.has_prefix` / `has_suffix`.
- **`string.find` returns indices**, not captures — use `string.match` when you
  want the captured text. Both take `(subject, pattern)` in that order.
- **Only `false` and `nil` are falsy.** `0` and `""` are both true.
- **Missing table keys return `nil`**, which is what makes `if SET[key] then`
  the idiomatic membership test — there is no `in` operator.

## The mise API surface

mise does not extend the Lua language. Everything it provides is:

- Globals `PLUGIN` (hooks hang off it) and `RUNTIME` (os/arch info)
- Modules via `require`: `http`, `json`, `semver`, `strings`, `file`, `cmd`,
  `env`, `archiver`, `html`, `log`

All of it is annotated in `types/mise-plugin.lua`, which is the practical API
reference for this plugin.

Note that the modules there are declared as file-locals, so
`require("http")` will not resolve to its type. For editor completion, annotate
at the call site:

```lua
local http = require("http") ---@type http
```

## Reference documentation

- [Tool plugin development](https://mise.jdx.dev/tool-plugin-development.html)
- [Lua modules reference](https://mise.jdx.dev/plugin-lua-modules.html)
- [Plugin publishing](https://mise.jdx.dev/plugin-publishing.html)
- [jdtls upstream](https://github.com/eclipse-jdtls/eclipse.jdt.ls)

## Submitting changes

1. Ensure checks pass: `mise run ci`
2. Open a pull request against `main`
