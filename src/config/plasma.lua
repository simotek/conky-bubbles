--- conky config options for plasma
-- @module config_plasma
-- @alias cc

pcall(function() require('cairo') end)

local config = {
    -- plasma wm --
    own_window_class = 'conky',
    own_window_type = 'normal',
    own_window_hints = 'undecorated,sticky,below,skip_taskbar,skip_pager',
}

return config
