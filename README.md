# Eclipse JDT Language Server (jdtls) mise plugin

[`mise`](https://mise.jdx.dev/) plugin for [`jdtls`](https://github.com/eclipse-jdtls/eclipse.jdt.ls),
for distributions where no native package exists or the packaged version is
outdated.

## Usage

```shell
mise plugin install https://github.com/coopernetes/mise-eclipse-jdtls

# List installable versions
mise ls-remote eclipse-jdtls

# Install and add to the current project's mise.toml
mise use eclipse-jdtls@1.60.0

# Run it
jdtls
```

Recommended project setup, which also provides the runtime dependencies below:

```toml
[tools]
java = "temurin-21"
python = "3.12"
eclipse-jdtls = "1.60.0"
```

## Requirements

- **mise 2026.2.1 or newer** — older releases fail with `module 'log' not
  found`. Run `mise self-update`.
- **python3** — `bin/jdtls` is a Python launcher.
- **A JRE** — recent jdtls releases need Java 21 or newer.

python3 and the JRE are declared to mise, so on 2026.7.3 or newer a missing one
is reported before anything downloads, with the package that provides it.

## Versions

| Selector | Installs |
| --- | --- |
| `1.60.0` | that milestone build |
| `latest` | the newest milestone |
| `latest-snapshot` | the current rolling snapshot |

Milestone versions are plain semver and immutable. `mise ls-remote` lists the
`1.x` releases that have a milestone build; pre-1.0 releases are excluded, as is
`1.59.0`, which upstream tagged but never published a build for. Asking for a
version with no build fails with an explicit error. See
[docs/milestone-coverage.md](./docs/milestone-coverage.md) for the full list.

## Snapshot builds

`latest-snapshot` is a rolling channel: CI builds of the next, unreleased
version, rebuilt several times a week. They are untested builds of unreleased
code — prefer a milestone unless you need an unreleased fix. Only the current
snapshot is installable, and `latest` never selects one implicitly.

> [!IMPORTANT]
> mise treats `latest-snapshot` as a prerelease, and excludes prereleases from
> version lookups by default. Installing works either way, but `mise outdated`
> and `mise upgrade` will not notice new snapshot builds — and `ls-remote` will
> not list the channel — unless you enable them:
>
> ```shell
> mise settings set prereleases true
> ```

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md), which covers how the plugin resolves
builds and why.

## License

MIT
