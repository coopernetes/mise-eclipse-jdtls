-- Git tags with no corresponding milestone build.
-- See docs/milestone-coverage.md (verified 2026-07-26).
local NO_MILESTONE = {
    ["1.59.0"] = true,
}

--- Returns a list of available versions for the tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- @param ctx {args: string[]} Context (args = user arguments)
--- @return table[] List of available versions
function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")
    local log = require("log")

    local repo_url = "https://api.github.com/repos/eclipse-jdtls/eclipse.jdt.ls/tags?per_page=100&page="
    local page = 1
    local moretags = true

    local alltags = {}

    repeat
        log.debug("GET " .. repo_url .. page)
        local resp, err = http.get({
            url = repo_url .. page,
        })

        if err ~= nil then
            error("Failed to fetch versions: " .. err)
        end
        if resp.status_code ~= 200 then
            error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
        end

        local tags = json.decode(resp.body)
        local count = 0
        for _, tag in ipairs(tags) do
            table.insert(alltags, tag)
            count = count + 1
        end
        log.debug("collected " .. count .. " tags from page " .. page)
        -- no more pages
        if count < 100 then
            moretags = false
        end
        page = page + 1
    until not moretags

    -- Process tags/releases
    local tag_table = {}
    local count = 0
    local set_latest = false
    for _, tag_info in ipairs(alltags) do
        local version = tag_info.name
        version = version:gsub("^v", "")

        if string.find(version, "^1%.") ~= nil and not NO_MILESTONE[version] then
            count = count + 1

            local note = nil
            if not set_latest then
                note = "latest"
                set_latest = true
            end
            table.insert(tag_table, {
                version = version,
                note = note,
            })
        end
    end

    local base_url = "https://download.eclipse.org/jdtls/snapshots"
    local latest_resp, err = http.try_get({
        url = base_url .. "/latest.txt",
    })
    if err ~= nil then
        error("could not fetch snapshot info: " .. err)
    elseif latest_resp.status_code == 200 then
        local strings = require("strings")
        local latest_filename = strings.trim_space(latest_resp.body)

        log.debug("latest filename: " .. latest_filename)

        local latest_checksum_resp = http.get({
            url = base_url .. "/" .. latest_filename .. ".sha256",
        })
        if latest_checksum_resp.status_code ~= 200 then
            log.debug("GET " .. base_url .. "/" .. latest_filename .. ".sha256, body: " .. latest_checksum_resp.body)
            error(
                "something went horribly wrong during latest snapshot checksum lookup. this is a plugin error. report to the developer"
            )
        end
        local checksum_value = strings.trim_space(latest_checksum_resp.body)

        -- Published as the literal "latest-snapshot" rather than the resolved
        -- build (e.g. 1.61.0-snapshot). mise looks up rolling versions by the
        -- *requested* string, so the version here, what the user requests, and
        -- what PreInstall returns must all be the same literal for update
        -- detection to work. See CONTRIBUTING.md.
        table.insert(tag_table, 1, {
            version = "latest-snapshot",
            note = "rolling snapshot build",
            rolling = true,
            checksum = checksum_value,
        })
    else
        log.debug("GET " .. base_url .. "/latest.txt" .. " body: " .. latest_resp.body)
        error("unexpected http response when fetching latest snapshot: " .. latest_resp.status_code)
    end

    log.debug("total tags: " .. count)
    return tag_table
end
