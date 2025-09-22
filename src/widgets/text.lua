--- A collection of Widget classes
-- @module widget_text
-- @alias wt

pcall(function() require('cairo') end)
pcall(function() require('cairo_text_helper') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local Widget = core.Widget

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table
local floor, ceil, clamp = math.floor, math.ceil, util.clamp


--- Common (abstract) base class for `StaticText` and `TextLine`.
-- @type Text
local Text = util.class(Widget)
w.Text = Text

-- @tparam tab args table of options
-- @tparam[opt=CAIRO_TEXT_ALIGN_LEFT] ?cairo_text_alignment_t args.align "CAIRO_TEXT_ALIGN_LEFT" (default), "center" or "right"
-- @tparam[opt=current_theme.default_font_family] ?string args.font_family
-- @tparam[opt=current_theme.default_font_size] ?number args.font_size
-- @tparam[opt=current_theme.default_font_direction] ?string
-- @tparam[opt=current_theme.default_font_script] ?string
-- @tparam[opt=current_theme.default_font_language] ?string
-- @tparam[opt=current_theme.default_text_color] ?string args.color a string containing a hex color code (default: `default_text_color`)
function Text:init(args)
    assert(getmetatable(self) ~= Text, "Cannot instanciate class Text directly.")
    self._align = args.align or CAIRO_TEXT_ALIGN_LEFT
    self._font_family = args.font_family or current_theme.default_font_family
    self._font_size = args.font_size or current_theme.default_font_size
    self._font_direction = args.font_direction or current_theme.default_font_direction
    self._font_script = args.font_script or current_theme.default_font_script
    self._font_language = args.font_language or current_theme.default_font_language
    local tmp_color = args.color or current_theme.default_text_color
    self._color = ch.convert_string_to_rgba(tmp_color)

    -- Set line_height
    local w, h = cairo_text_hp_text_size("", self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)
    self._line_height = h

    -- These will get updated with font but need to be a number to compare with
    self._min_width = 1
    self._min_height = 1
end


--- Draw text substuting in Conky variables.
-- Text line will be updated on each cycle as per Conky's text
-- Section, some variables such as formatting and positioning
-- may not be honored.
-- @type ConkyText
local ConkyText = util.class(Text)
w.ConkyText = ConkyText

-- @string text Text to be displayed, can include conky variables.
-- @tparam table args table of options, see `Text:init`
-- @tparam args.pattern a cairo mesh to use as the fill
-- @number args.border_width Width of the border
-- @string args.border_color a border color to use.
function ConkyText:init(text, args)
    Text.init(self, args)

    self._pattern = args.pattern
    self._border_width = args.border_width
    if args.border_color then
        self._border_color = ch.convert_string_to_rgba(args.border_color)
    else
        self._border_color = nil
    end

    self._lines = {}
    self._render_lines = {}
    local _, line_count = text:gsub("[^\n]*", function(line)
        table.insert(self._lines, line)
    end)
end

function ConkyText:update(update_count)
    local needs_rebuild = false
    local new_height = 0
    local lw = self._min_width
    local lh = self._line_height
    for i, line in ipairs(self._lines) do
        local sub_text = conky_parse(line)
        self._render_lines[i] = sub_text
        local w, h = cairo_text_hp_text_size(sub_text, self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)
        if w > lw then
            lw = w
        end
        if h > lh then
            lh = h
        end
    end
    if lw > self._min_width then
        self._min_width = lw
        needs_rebuild = true
    end
    if lh > self._line_height then
        self._line_height = lh
    end
    new_height = lh*#self._lines
    if new_height > self._min_height then
        self._min_height = new_height
        needs_rebuild = true
    end

    return needs_rebuild
end

function ConkyText:render(cr)
    cairo_set_source_rgba(cr, unpack(self._color))
    for i, line in ipairs(self._render_lines) do
        local y = (i - 1) * self._line_height
        cairo_text_hp_show(cr, self._x, y, line, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
        if self._border_width then
            cairo_set_line_width(cr, self._border_width)
            cairo_set_source_rgba(cr, unpack(self._border_color))
            cairo_stroke(cr)
        end
    end
end

--- Draw some unchangeable text.
-- Use this widget for text that will never be updated.Text
-- @type StaticText
local StaticText = util.class(Text)
w.StaticText = StaticText

-- @string text Text to be displayed.
-- @tparam ?table args table of options, see `Text:init`
-- @tparam args.pattern a cairo pattern to use as the fill
-- @number  args.border_width Width of the border
-- @string args.border_color a border color to use.
function StaticText:init(text, args)
    Text.init(self, args or {})

    self._pattern = args.pattern
    self._border_width = args.border_width
    if args.border_color then
        self._border_color = ch.convert_string_to_rgba(args.border_color)
    else
        self._border_color = nil
    end

    self._lines = {}
    local text = text .. "\n"

    for line in text:gmatch("(.-)\n") do
        table.insert(self._lines, line)
    end

    self.height = #self._lines * self._line_height
    local w, h = cairo_text_hp_text_size(text, self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)
    self._min_width = w
    self.width = w
    self._line_height = h
    self._min_height = #self._lines * h
    self.height = #self._lines * h

end

function StaticText:render(cr)
    if self._pattern then
        cairo_set_source(cr, self._pattern)
    else
        cairo_set_source_rgba(cr, unpack(self._color))
    end
    for i, line in ipairs(self._lines) do
        local y = (i - 1) * self._line_height
        cairo_text_hp_show(cr, self._x, y, line, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
        if self._border_width then
            cairo_set_line_width(cr, self._border_width)
            cairo_set_source_rgba(cr, unpack(self._border_color))
            cairo_stroke(cr)
        end
    end
end


--- Draw a single line of changeable text.
-- Text line can be updated on each cycle via `set_text`.
-- @type TextLine
local TextLine = util.class(Text)
w.TextLine = TextLine

--- @tparam table args table of options, see `Text:init`
function TextLine:init(args)
    Text.init(self, args)
    self.needs_rebuild = false

    self._text = ""
end

--- Update the text line to be displayed.
-- @string text
function TextLine:set_text(text)
    self._text = text

    local w, h = cairo_text_hp_text_size(self._text, self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)
    if w > self._min_width then
        self._min_width = w
        self.needs_rebuild = true
    end
    if h > self._min_height then
        self._min_height = h
        self.needs_rebuild = true
    end

end


function TextLine:update(update_count)
    if self.needs_rebuild then
        self.needs_rebuild = false
        return true
    end
end

function TextLine:render(cr)
    cairo_set_source_rgba(cr, unpack(self._color))
    cairo_text_hp_show(cr, 0, 0, self._text, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
end


return w
