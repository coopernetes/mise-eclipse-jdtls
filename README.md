# Eclipse JDT Language Server (jdtls) mise plugin

[`mise`](https://mise.jdx.dev/) plugin for [`jdtls`](https://github.com/eclipse-jdtls/eclipse.jdt.ls),
for distributions where no native package exists or the packaged version is
outdated.

> [!NOTE]
> Upstream publishes no GitHub release artifact. The only prebuilt binaries are
> the *milestone* builds on <https://download.eclipse.org/jdtls/milestones/> and
> the rolling *snapshot* builds on
> <https://download.eclipse.org/jdtls/snapshots/>. This plugin installs both; it
> does not compile from source.

## Requirements

jdtls ships `bin/jdtls` as a Python launcher that starts a JVM, so you need
both at runtime:

- **python3** — runs the launcher script
- **A JRE** — runs the language server itself. Recent jdtls releases require
  Java 21 or newer; check the upstream release notes for the exact floor of the
  version you install.

mise can provide both. Because the launcher resolves `python3` from `PATH` at
exec time, a mise-managed python satisfies it:

```toml
[tools]
java = "temurin-21"
python = "3.12"
eclipse-jdtls = "1.60.0"
```

## Usage

```shell
mise plugin install https://github.com/coopernetes/mise-eclipse-jdtls

# List installable versions
mise ls-remote eclipse-jdtls

# Install a specific version
mise install eclipse-jdtls@1.60.0

# Install and add to the current project's mise.toml
mise use eclipse-jdtls@1.60.0

# Run it
jdtls
```

Milestone versions are plain semver (`1.60.0`), matching the upstream milestone
directories. The rolling snapshot channel is `latest-snapshot` — see below.

## Available versions

`mise ls-remote eclipse-jdtls` lists jdtls `1.x` releases that have a milestone
build. Two deliberate exclusions:

- **Pre-1.0 releases** (2017–2021) are filtered out. They are old enough to be
  of no practical use.
- **`1.59.0`** is tagged upstream but has no milestone build, so it cannot be
  installed. Use `1.60.0` instead.

`1.59.0` is currently the only gap in the 1.x range. See
[docs/milestone-coverage.md](./docs/milestone-coverage.md) for the full
comparison of Git tags against published milestones, and for how to regenerate
it. Requesting a version with no milestone build fails with an explicit error
rather than a confusing download failure.

## Snapshot builds

Upstream also publishes rolling snapshot builds from
<https://download.eclipse.org/jdtls/snapshots/>. These are CI builds of the
next, unreleased version, rebuilt several times a week, and so run ahead of the
newest milestone.

```shell
mise install eclipse-jdtls@latest-snapshot
```

Only the current snapshot is installable. Historical snapshot builds are not
supported: upstream keeps dozens of timestamped archives of the same version,
and pinning one has no lasting value.

`latest-snapshot` is a rolling channel rather than a fixed version: the same
version string tracks whatever upstream has most recently published. mise
records the checksum of the build it installed, so `mise upgrade` reinstalls the
snapshot once a newer archive appears. Milestone versions are immutable and
never change once installed.

`eclipse-jdtls@latest` always resolves to the newest **milestone** — snapshots
are never selected implicitly, so you have to ask for one by name.

Snapshots are untested builds of unreleased code. Prefer a milestone build
unless you specifically need an unreleased fix.

## How it works

Milestone and snapshot archives both carry a build timestamp in their filename
that cannot be derived from the version. Upstream publishes a `latest.txt`
alongside them naming the current archive, so the plugin resolves the download
URL from that and verifies it against the accompanying `.sha256`.

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

## License

MIT
