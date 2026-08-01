--- Requires a mise-provided Lua module, reporting the version requirement
--- rather than a bare "module not found" when running on an older mise.
--- @param name string
--- @return table
local function require_mise_module(name)
    local ok, mod = pcall(require, name)
    if not ok then
        error(
            "this plugin requires mise 2026.2.1 or newer (Lua module '"
                .. name
                .. "' is unavailable). Run `mise self-update`."
        )
    end
    return mod
end

--- Resolves the archive currently published in a milestone or snapshot
--- directory. Both publish a latest.txt naming the timestamped archive, plus a
--- matching .sha256 holding the bare hash.
--- @param base_url string Directory URL, without a trailing slash
--- @return table|nil info {url, checksum}, or nil on failure
--- @return string|nil reason Why the lookup failed, set whenever info is nil
local function get_filename(base_url)
    local http = require_mise_module("http")
    local log = require_mise_module("log")
    local strings = require_mise_module("strings")

    local url = base_url .. "/latest.txt"
    log.debug("GET " .. url)
    local resp = http.get({
        url = url,
    })
    if resp.status_code == 404 then
        return nil, "no build is published at " .. base_url
    elseif resp.status_code ~= 200 then
        log.debug("GET " .. url .. " body: " .. resp.body)
        return nil, url .. " returned HTTP " .. resp.status_code
    end

    -- trims trailing newline
    local filename = strings.trim_space(resp.body)

    local checksum_url = base_url .. "/" .. filename .. ".sha256"
    log.debug("GET " .. checksum_url)
    local checksum_resp = http.get({
        url = checksum_url,
    })
    if checksum_resp.status_code ~= 200 then
        log.debug("GET " .. checksum_url .. " body: " .. checksum_resp.body)
        return nil, checksum_url .. " returned HTTP " .. checksum_resp.status_code
    end

    return {
        url = base_url .. "/" .. filename,
        checksum = strings.trim_space(checksum_resp.body),
    }
end

--- Returns download information for a specific version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if version == "latest-snapshot" or version:match("%-snapshot$") then
        local snapshot_file, reason = get_filename("https://download.eclipse.org/jdtls/snapshots")
        if snapshot_file == nil then
            error("Cannot install " .. version .. ": " .. reason)
        end
        -- Echo the requested version back unchanged. mise stores the checksum
        -- under the resolved version but looks it up by the *requested* one, so
        -- resolving "latest-snapshot" to a concrete build would break update
        -- detection. See CONTRIBUTING.md.
        return {
            version = version,
            url = snapshot_file.url,
            sha256 = snapshot_file.checksum,
        }
    end

    local base_url = "https://download.eclipse.org/jdtls/milestones/" .. version
    local milestone_file, reason = get_filename(base_url)
    if milestone_file == nil then
        error("Cannot install " .. version .. ": " .. reason)
    end
    return {
        version = version,
        url = milestone_file.url,
        sha256 = milestone_file.checksum,
    }
end
