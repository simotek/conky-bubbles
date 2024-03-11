--- A collection of GPU Widget classes
-- @module widget_gpu
-- @alias wgpu

pcall(function() require('cairo') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local mem = require('src/widgets/memory')
local text  = require('src/widgets/text')
local Widget = core.Widget

local TextLine = text.TextLine
local Filler, Rows, Columns = core.Filler, core.Rows, core.Columns

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

local sin, cos, tan, PI = math.sin, math.cos, math.tan, math.pi
local floor, ceil, clamp = math.floor, math.ceil, util.clamp

--- Compound widget to display GPU and VRAM usage.
-- @type Gpu
local Gpu = util.class(core.Rows)
w.Gpu = Gpu

--- no options
function Gpu:init()
    self._usebar = core.Bar{ticks={.25, .5, .75}, unit="%"}

    local _, mem_total = data.gpu_memory()
    self._membar = mem.MemoryBar{total=mem_total / 1024}
    self._membar.update = function()
        self._membar:set_used(data.gpu_memory() / 1024)
    end
    core.Rows.init(self, {self._usebar, core.Filler{height=4}, self._membar})
end

function Gpu:update()
    self._usebar:set_fill(data.gpu_percentage() / 100)

    local color = {w.temperature_color(data.gpu_temperature(), 30, 80)}
    self._usebar.color = color
    self._membar.color = color
end

--- Table of processes for the GPU, sorted by VRAM usage
-- @type GpuTop
local GpuTop = util.class(core.Rows)
w.GpuTop = GpuTop

--- @tparam table args table of options
-- @tparam[opt=5] ?int args.lines how many processes to display
-- @tparam ?string args.font_family
-- @tparam ?number args.font_size
-- @tparam ?string args.color a string containing a hex color code (default: `default_text_color`)
function GpuTop:init(args)
    self._lines = args.lines or 5
    self._font_family = args.font_family or current_theme.default_font_family
    self._font_size = args.font_size or current_theme.default_font_size
    local tmp_color = args.color or current_theme.default_text_color
    self._rows = {}
    self._process_names = {}
    self._process_mem = {}

    for i=1,self._lines do
        line_color = current_theme.default_text_color
        if current_theme.top_colors then
            if current_theme.top_colors[i] then
                line_color = current_theme.top_colors[i]
            else
                line_color = current_theme.top_colors[#current_theme.top_colors]
            end
        end
        self._process_names[i] = TextLine({color=line_color})
        self._process_mem[i] = TextLine({align=CAIRO_TEXT_ALIGN_RIGHT, color=line_color})
        self._rows[i] = Columns({self._process_names[i], Filler{width=10}, self._process_mem[i]})
    end

    core.Rows.init(self, self._rows)
end

function GpuTop:update(update_count)
    self._processes = data.gpu_top()

    rebuild = false

    for i=1,self._lines do
        self._process_names[i]:set_text(self._processes[i][1] or "")
        self._process_mem[i]:set_text(self._processes[i][2].."MiB" or "")

        if self._process_names[i].needs_rebuild or self._process_mem[i].needs_rebuild then
            rebuild = true
        end
    end

    res = core.Rows.update(self, update_count)

    if rebuild == false then
        return res
    end

    return rebuild
end

return w
