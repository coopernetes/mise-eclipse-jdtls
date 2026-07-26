-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    name = "eclipse-jdtls",
    version = "0.1.0",
    description = "A mise tool plugin for eclipse-jdtls",
    author = "coopernetes",
    updateUrl = "https://github.com/coopernetes/mise-eclipse-jdtls",

    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".eclipse-jdtls-version",
    --     ".eclipse-jdtlsrc"
    -- }
}
