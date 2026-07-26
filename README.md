# Eclipse JDT Language Server (jdtls) mise plugin

[`mise`](https://mise.jdx.dev/) plugin for [`jdtls`](https://github.com/eclipse-jdtls/eclipse.jdt.ls),
for distributions where no native package exists or the packaged version is
outdated.

> [!NOTE]
> Upstream publishes prebuilt binaries only as *milestone* builds on
> <https://download.eclipse.org/jdtls/milestones/>. There is no GitHub release
> artifact. This plugin installs those milestone builds; it does not compile
> from source.

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
mise plugin install https://github.com/coopernetes/mise-eclipse-jdtls-plugin

# List installable versions
mise ls-remote eclipse-jdtls

# Install a specific version
mise install eclipse-jdtls@1.60.0

# Install and add to the current project's mise.toml
mise use eclipse-jdtls@1.60.0

# Run it
jdtls
```

Versions are plain semver (`1.60.0`), matching the upstream milestone
directories.

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

## How it works

The plugin reads the `latest.txt` file that upstream publishes in each
milestone directory to resolve the timestamped archive name, then hands mise
the archive URL along with the accompanying `.sha256` checksum. mise does the
download, verification, and extraction.

The milestone archive extracts to a flat layout (`bin/`, `plugins/`,
`config_*/`, `features/`) which is already the structure jdtls expects, so
there is no post-install step.

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

## License

MIT
