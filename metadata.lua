-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    name = "eclipse-jdtls",
    version = "0.1.1",
    description = "Eclipse JDT Language Server (jdtls) prebuilt milestone and snapshot builds",
    author = "coopernetes",
    updateUrl = "https://github.com/coopernetes/mise-eclipse-jdtls",

    -- jdtls ships bin/jdtls as a Python launcher that starts a JVM, so both
    -- are needed to run the server. mise reports these before installing and
    -- offers to install them via the system package manager, instead of
    -- leaving the user with `env: 'python3': No such file or directory`.
    --
    -- Note that mise cannot offer to satisfy these with mise-managed tools,
    -- so a user who provides python or java through mise itself may still see
    -- these reported if they are not on PATH at the time of the check. Adding
    -- them to the project's [tools] is documented in the README.
    --
    -- Requires mise 2026.7.3 or newer; older releases ignore this field.
    systemDependencies = {
        {
            bin = "python3",
            packages = {
                apt = "python3",
                dnf = "python3",
                pacman = "python",
                apk = "python3",
                brew = "python3",
            },
        },
        {
            bin = "java",
            packages = {
                apt = "default-jre-headless",
                dnf = "java-latest-openjdk-headless",
                pacman = "jre-openjdk-headless",
                apk = "openjdk21-jre-headless",
                brew = "openjdk",
            },
        },
    },

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".eclipse-jdtls-version",
    --     ".eclipse-jdtlsrc"
    -- }
}
