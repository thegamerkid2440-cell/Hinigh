
--[[
  INFINITE CARNAGE
  MASTER GITHUB LOADER

  Loads:
  1. Gojo Domain
  2. Sukuna Domain
  3. My Boxing Domain
  4. ALL Combined Domain
  5. Red / Blue / Purple / Punch Combat

  One execution in Delta.
]]

local DOMAIN =
    "https://raw.githubusercontent.com/" ..
    "thegamerkid2440-cell/" ..
    "Domain-expansion/main/"

local COMBAT =
    "https://raw.githubusercontent.com/" ..
    "thegamerkid2440-cell/" ..
    "Hinigh/main/"

local function loadScript(name, url)
    print("Loading " .. name .. "...")

    local ok, err = pcall(function()
        local source = game:HttpGet(url)

        if type(source) ~= "string"
            or #source < 20 then
            error("Empty script")
        end

        if source:lower():find("<!doctype", 1, true)
            or source:lower():find("<html", 1, true)
            or source:find("404: Not Found", 1, true) then
            error("GitHub file unavailable")
        end

        local executable, compileError =
            loadstring(source)

        if not executable then
            error(compileError)
        end

        executable()
    end)

    if ok then
        print(name .. " loaded!")
    else
        warn(name .. " FAILED: " .. tostring(err))
    end

    return ok
end

-- This is your existing domain launcher.
-- It loads gojo.lua, sukuna.lua,
-- mydomain.lua and all.lua itself.

local domainsLoaded = loadScript(
    "ALL FOUR DOMAINS",
    DOMAIN .. "cobine.lua"
)

-- Separate combat GUI:
-- Red, Blue, Purple and Punch

local combatLoaded = loadScript(
    "COMBAT SYSTEM",
    COMBAT .. "combat.lua"
)

if domainsLoaded and combatLoaded then
    print("INFINITE CARNAGE FULLY LOADED!")
else
    warn("Some files could not be loaded.")
    warn("Check GitHub filenames and uploads.")
end
