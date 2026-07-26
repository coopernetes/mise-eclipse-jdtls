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
    local semver = require("semver")
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
        for _,tag in ipairs(tags) do
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
    for _, tag_info in ipairs(alltags) do
        local version = tag_info.name
        version = version:gsub("^v", "")

        if string.find(version, "^1%.") ~= nil and not NO_MILESTONE[version] then

            count = count + 1

            table.insert(tag_table, {
                version = version,
                note = nil
            })
        end
    end

    log.debug("total tags: " .. count)

    local sorted_tags = semver.sort_by(tag_table, "version")
    if #sorted_tags == 0 then
        error("no installable jdtls versions found")
    end
    sorted_tags[#sorted_tags].note = "latest"
    return sorted_tags
end
