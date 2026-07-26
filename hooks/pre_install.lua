local http = require("http")
local log = require("log")

local function get_milestone_filename(version)
    local base_url = "https://download.eclipse.org/jdtls/milestones/" .. version
    local url = base_url .. "/latest.txt"
    log.debug("GET " .. url)
    local resp = http.get({
        url = url
    })
    if resp.status_code == 404 then
        log.debug("got 404, body: " .. resp.body)
        return nil
    end

    -- trims trailing newline
    local strings = require("strings")
    local filename = strings.trim_space(resp.body)

    log.debug("GET " .. base_url .. "/" .. filename .. ".sha256")
    local checksum_resp = http.get({
        url = base_url .. "/" .. filename .. ".sha256"
    })
    local checksum = ""
    if checksum_resp.status_code ~= 200 then
        log.warn("GET " .. filename .. ".sha256 failed, got " .. checksum_resp.status_code)
        log.debug("body: " .. checksum_resp.body)
    else
        checksum = strings.trim_space(checksum_resp.body)
    end
    return {
        filename = filename,
        checksum = checksum
    }
end

--- Returns download information for a specific version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local milestone_download_base = "https://download.eclipse.org/jdtls/milestones/"
    local maybe_milestone = get_milestone_filename(version)
    if maybe_milestone ~= nil then
        return {
            version = version,
            url = milestone_download_base .. version .. "/" .. maybe_milestone.filename,
            sha256 = maybe_milestone.checksum,
        }
    else
        error("Cannot install " .. version .. ", no milestone binary exists. Try another version.")
    end
end

-- Helper function for platform detection (uncomment and modify as needed)
--[[
local function get_platform()
    -- RUNTIME object is provided by mise/vfox
    -- RUNTIME.osType: "Windows", "Linux", "Darwin"
    -- RUNTIME.archType: "amd64", "386", "arm64", etc.

    local os_name = RUNTIME.osType:lower()
    local arch = RUNTIME.archType

    -- Map to your tool's platform naming convention
    -- Adjust these mappings based on how your tool names its releases
    local platform_map = {
        ["darwin"] = {
            ["amd64"] = "darwin-amd64",
            ["arm64"] = "darwin-arm64",
        },
        ["linux"] = {
            ["amd64"] = "linux-amd64",
            ["arm64"] = "linux-arm64",
            ["386"] = "linux-386",
        },
        ["windows"] = {
            ["amd64"] = "windows-amd64",
            ["386"] = "windows-386",
        }
    }

    local os_map = platform_map[os_name]
    if os_map then
        return os_map[arch] or "linux-amd64"  -- fallback
    end

    -- Default fallback
    return "linux-amd64"
end
--]]
