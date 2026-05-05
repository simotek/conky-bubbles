--- Helper function to generate conky config table
--- Configuration Loader Module
-- Helper module to generate and merge conky config tables based on the
-- currently running desktop environment and display server.
-- @module config_loader

local util = require('src/util')
local cl = {}

--- Loads and merges the appropriate conky configurations.
-- Determines the current desktop environment and display server,
-- loads the respective configuration tables, and merges them with
-- the core configuration and the provided script configuration.
-- @tparam table script_config Custom configuration table to be merged on top of the defaults.
-- @treturn table The fully merged configuration table.
function cl.load_config(script_config)
    local core_config = require('src/config/core')
    local wm_config = {}

    if os.getenv("DESKTOP") == "Enlightenment" then
        wm_config = require('src/config/plasma_enlightenment')
        print("Bubbles: Using Enlightenment Config")
    elseif os.getenv("DESKTOP_SESSION") == "plasmawayland" 
        or os.getenv("DESKTOP_SESSION") == "plasma" then
        wm_config = require('src/config/plasma_enlightenment')
        print("Bubbles: Using Plasma Config")
    else
        wm_config = require('src/config/awesome')
        print("Bubbles: Using Awesome Config")
    end

    local tmp_config = util.merge_table(core_config, wm_config)
    if Using_Wayland then
        local wayland_config = require('src/config/wayland')
        tmp_config = util.merge_table(tmp_config, wayland_config)
    end
    return util.merge_table(tmp_config, script_config)
end

return cl