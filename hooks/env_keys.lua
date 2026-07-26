--- Configures environment variables for the installed tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook
--- @param ctx {path: string, runtimeVersion: string, sdkInfo: table} Context
--- @return table[] List of environment variable definitions
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    -- Milestone archives already ship a bin/ directory containing the jdtls
    -- launcher, so exposing it on PATH is all that is required.
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }
end
