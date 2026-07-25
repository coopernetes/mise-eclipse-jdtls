# Contributing

This plugin is a mise tool plugin built on the vfox-style Lua hooks architecture.

## Setting up a development environment

Install the development tools declared in `mise.toml`:

```bash
mise install
```

Install the pre-commit hooks (optional but recommended):

```bash
hk install
```

This sets up automatic linting and formatting on git commits.

## Local testing

1. Link your working copy as the plugin implementation:

```bash
mise plugin link --force eclipse-jdtls .
```

2. Run tests:

```bash
mise run test
```

3. Run linting:

```bash
mise run lint     # hk check
mise run lint-fix # hk fix, auto-fixes what it can
mise run format   # stylua only
```

4. Run the full CI suite:

```bash
mise run ci
```

## Code quality

Linting and pre-commit hooks are managed by [hk](https://hk.jdx.dev), configured in `hk.pkl`:

- **Formatting**: `stylua` formats Lua code (`stylua.toml`)
- **Static analysis**: `lua-language-server --check` (`.luarc.json`)
- **GitHub Actions linting**: `actionlint` validates workflows

Manual commands:

```bash
hk check      # Run all linters (same as mise run lint)
hk fix        # Run linters and auto-fix issues
```

## Debugging

Enable debug output from mise while installing:

```bash
MISE_DEBUG=1 mise install eclipse-jdtls@latest
```

## Project layout

- `metadata.lua` – Plugin metadata and configuration
- `hooks/available.lua` – Returns available versions from upstream
- `hooks/pre_install.lua` – Returns artifact URL for a given version
- `hooks/post_install.lua` – Post-installation setup (permissions, moving files)
- `hooks/env_keys.lua` – Environment variables to export (`PATH`, etc.)
- `types/mise-plugin.lua` – Type definitions for the plugin API
- `mise-tasks/` – Task scripts (currently `test`)
- `mise.toml` – Development tools and task definitions
- `hk.pkl` – Linting and pre-commit hook configuration
- `stylua.toml` – Lua formatting configuration
- `.luarc.json` – lua-language-server configuration
- `.github/workflows/ci.yml` – GitHub Actions CI pipeline

## Hook implementation notes

### Platform detection

The `RUNTIME` object is provided by mise/vfox:

- `RUNTIME.osType`: `"Windows"`, `"Linux"`, `"Darwin"`
- `RUNTIME.archType`: `"amd64"`, `"386"`, `"arm64"`, etc.

Map these to the naming convention used by the upstream artifacts. Note that
jdtls pre-built binaries are platform-independent Java archives, so most hooks
here do not need to branch on platform.

### Checksum verification

`pre_install.lua` may return a `sha256` alongside the URL:

```lua
return {
    version = version,
    url = url,
    sha256 = "abc123...",
}
```

### Error handling

Fail loudly rather than returning partial results:

```lua
if err ~= nil then
    error("Failed to fetch versions: " .. err)
end

if resp.status_code ~= 200 then
    error("API returned status " .. resp.status_code)
end
```

## Reference documentation

- [Tool plugin development](https://mise.jdx.dev/tool-plugin-development.html) – Complete guide to plugin development
- [Lua modules reference](https://mise.jdx.dev/plugin-lua-modules.html) – Available Lua modules and functions
- [Plugin publishing](https://mise.jdx.dev/plugin-publishing.html) – How to publish a plugin
- [jdtls upstream](https://github.com/eclipse-jdtls/eclipse.jdt.ls)

## Submitting changes

1. Ensure all checks pass: `mise run ci`
2. Open a pull request against `main`
