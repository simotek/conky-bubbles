--- A collection of Disk Drive Widget classes
-- @module widget_drive
-- @alias wdrive

pcall(function() require('cairo') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local ind = require('src/widgets/indicator')
local text = require('src/widgets/text')
local Widget, Rows = core.Widget, core.Rows
local ConkyText, StaticText = core.ConkyText, core.StaticText

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

local sin, cos, tan, PI = math.sin, math.cos, math.tan, math.pi
local floor, ceil, clamp = math.floor, math.ceil, util.clamp

--- Visualize drive usage and temperature in a colorized Bar.
-- Also writes temperature as text.
-- This widget is exptected to be combined with some special conky.text.
-- @type Drive
local Drive = util.class(Rows)
w.Drive = Drive

--- @string path e.g. "/home"
--- @tparam table args table of options
-- @string args.device this code can't detect lvm's etc so hardcode
-- @string args.physical_device this code can't detect lvm's etc so hardcode
function Drive:init(path, args)
    self._path = path
    self._device = args.physical_device or nil
    self._physical_device = args.physical_device or nil

    self._manual_mode = false

    if self._physical_device and self._device then
        self._manual_mode = true
    end

    self._read_led = ind.LED{radius=2, color=current_theme.green_led_color}
    self._write_led = ind.LED{radius=2, color=current_theme.red_led_color}
    self._temperature_text = text.TextLine{align=CAIRO_TEXT_ALIGN_RIGHT}
    self._bar = core.Bar{}
    local header_font = {color=current_theme.header_color,font_family=current_theme.default_font_family, font_size=current_theme.header_font_size}
    local right_font = {align=CAIRO_TEXT_ALIGN_RIGHT}
    core.Rows.init(self, {
        StaticText("-- "..self._path.." --", header_font),
        core.Columns{
            core.Filler{},
            core.Filler{width=6, widget=core.Rows{
                core.Filler{},
                self._read_led,
                core.Filler{height=1},
                self._write_led,
            }},
            core.Filler{width=30, widget=self._temperature_text},
        },
        core.Filler{height=4},
        self._bar,
        core.Columns{
            ConkyText("${fs_used "..self._path.."}  /  ${fs_size "..self._path.."}", {}),
            ConkyText("${fs_used_perc "..self._path.."}%", right_font)
        },
    })

    self._real_height = self.height
    self.height = 0
    self._is_mounted = false
end

function Drive:layout(...)
    return self._is_mounted and Rows.layout(self, ...) or {}
end

function Drive:update()
    local was_mounted = self._is_mounted
    self._is_mounted = data.is_mounted(self._path)
    if self._is_mounted then
        if not was_mounted and not self._manual_mode then
            self._device, self._physical_device = unpack(data.find_devices()[self._path])
        end
        self._bar:set_fill(data.drive_percentage(self._path) / 100)

        local read = data.diskio(self._device, "read", "B")
        local read_magnitude = util.log2(read)
        self._read_led:set_brightness(read_magnitude / 30)

        local write = data.diskio(self._device, "write", "B")
        local write_magnitude = util.log2(write)
        self._write_led:set_brightness(write_magnitude / 30)

        local temperature = nil
        if self._physical_device then
            temperature = data.device_temperatures()[self._physical_device]
        end
        if temperature then
            self._bar.color = {w.temperature_color(temperature, 35, 65)}
            self._temperature_text:set_text(math.floor(temperature + 0.5) .. "°C")
        else
            self._bar.color = {0.8, 0.8, 0.8}
            self._temperature_text:set_text("––––")
        end
        self.height = self._real_height
    else
        self.height = 0
    end

    return (self._is_mounted ~= was_mounted) or core.Rows.update(self)
end

return w
