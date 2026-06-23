--- A collection of Network Widget classes
-- @module widget_network
-- @alias wnet

pcall(function() require('cairo') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local ind = require('src/widgets/indicator')
local text  = require('src/widgets/text')
local Widget, Columns, Filler = core.Widget, core.Columns, core.Filler
local ConkyText, StaticText = text.ConkyText, text.StaticText
-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

local sin, cos, tan, PI = math.sin, math.cos, math.tan, math.pi
local floor, ceil, clamp = math.floor, math.ceil, util.clamp

--- Graphs for up- and download speed.
-- This widget assumes that your conky.text adds some text between the graphs.
-- @type Network
local Network = util.class(core.Rows)
w.Network = Network

--- @tparam table args table of options
-- @string args.interface e.g. "eth0"
-- @tparam ?number args.graph_height passed to `Graph:init`
-- @number[opt=1024] args.downspeed passed as args.max to download speed graph
-- @number[opt=1024] args.upspeed passed as args.max to upload speed graph
function Network:init(args)
    self.provided_interface = args.interface
    self._downspeed_graph = ind.Graph{height=args.graph_height, max=args.downspeed or 1024}
    self._upspeed_graph = ind.Graph{height=args.graph_height, max=args.upspeed or 1024}

    local status_font = {color=current_theme.secondary_text_color,font_family=current_theme.default_font_family, font_size=current_theme.default_font_size, align=CAIRO_TEXT_ALIGN_RIGHT}

    if self.provided_interface then
       self.interface = self.provided_interface
    else
        self._last_interface = data.get_active_network_interface()
        self.interface = self._last_interface
    end

    local downspeed_text = ""
    local downtotal_text = ""
    local upspeed_text = ""
    local uptotal_text = ""

    if self.interface then
        downspeed_text = "${downspeed "..self.interface.."}"
        downtotal_text = "${totaldown "..self.interface.."}"
        upspeed_text = "${upspeed "..self.interface.."}"
        uptotal_text = "${totalup "..self.interface.."}"
    end

    self._rows = {}
    self._downspeed = ConkyText(downspeed_text, {align=CAIRO_TEXT_ALIGN_RIGHT})
    self._downtotal = ConkyText(downtotal_text, {align=CAIRO_TEXT_ALIGN_RIGHT})
    self._upspeed = ConkyText(upspeed_text, {align=CAIRO_TEXT_ALIGN_RIGHT})
    self._uptotal = ConkyText(uptotal_text, {align=CAIRO_TEXT_ALIGN_RIGHT})

    self._rows[1] = Columns({StaticText("Down",{}), Filler{width=10}, self._downspeed})
    self._rows[2] = Columns({StaticText("Total",{}), Filler{width=10}, self._downtotal})
    self._rows[3] = self._downspeed_graph
    self._rows[4] = Columns({StaticText("Up",{}), Filler{width=10}, self._upspeed})
    self._rows[5] = Columns({StaticText("Total",{}), Filler{width=10}, self._uptotal})
    self._rows[6] = self._upspeed_graph


    core.Rows.init(self, self._rows)
end

function Network:update()

    local down, up = 0,0
    if self.provided_interface then
        down, up = data.network_speed(self.provided_interface)
    else
        local new_interface = data.get_active_network_interface()
        if new_interface then
            down, up = data.network_speed(new_interface)
        end

        if new_interface ~= self._last_interface then
            self._last_interface = new_interface
            self.interface = new_interface
            if new_interface then
                self._downspeed:setText("${downspeed "..self.interface.."}")
                self._downtotal:setText("${totaldown "..self.interface.."}")
                self._upspeed:setText("${upspeed "..self.interface.."}")
                self._uptotal:setText("${totalup "..self.interface.."}")
            else
                self._downspeed:setText("")
                self._downtotal:setText("")
                self._upspeed:setText("")
                self._uptotal:setText("")
            end
        end
    end
    self._downspeed_graph:add_value(down)
    self._upspeed_graph:add_value(up)

    core.Rows.update(self)
end

return w
