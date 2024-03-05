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

--- @tparam table args table of options
-- @tparam ?cairo_text_alignment_t args.align "CAIRO_TEXT_ALIGN_LEFT" (default), "center" or "right"
-- @tparam[opt=current_theme.default_font_family] ?string args.font_family
-- @tparam[opt=current_theme.default_font_size] ?number args.font_size
-- @tparam[opt=current_theme.default_font_direction] ?string
-- @tparam[opt=current_theme.default_font_script] ?string
-- @tparam[opt=current_theme.default_font_language] ?string
-- @tparam ?string args.color a string containing a hex color code (default: `default_text_color`)
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

    -- try to match conky's line spacing:
    local font_extents = ch.font_extents(self._font_family, self._font_size,
                                         self._font_slant, self._font_weight)
    self._line_height = font_extents.height + 1

    local line_spacing = font_extents.height - (font_extents.ascent + font_extents.descent)
    self._baseline_offset = font_extents.ascent + 0.5 * line_spacing + 1

    -- Set line_height
    local w, h = cairo_text_hp_text_size("", self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)
    self._line_height = h

    -- These will get updated with font but need to be a number to compare with
    self._min_width = 1
    self._min_height = 1
end

function Text:layout(width)
    -- Alignment handled by cairo api
    -- Todo, Allow setting offsets at object creation
    self._x = 0
    self._y = 0
end

--- Draw text substuting in Conky variables.
-- Text line will be updated on each cycle as per Conky's text
-- Section, some variables such as formatting and positioning
-- may not be honored.
-- @type ConkyText
local ConkyText = util.class(Text)
w.ConkyText = ConkyText

--- @string text Text to be displayed, can include conky variables.
--- @tparam table args table of options, see `Text:init`
function ConkyText:init(text, args)
    Text.init(self, args)

    self._lines = {}
    self._render_lines = {}
    local _, line_count = text:gsub("[^\n]*", function(line)
        table.insert(self._lines, line)
    end)
    self.height = line_count * self._line_height
end

function ConkyText:update(update_count)
    needs_rebuild = false
    lw = self._min_width
    lh = self._line_height
    for i, line in ipairs(self._lines) do
        sub_text = conky_parse(line)
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
    end
    if lh > self._line_height then
        self._line_height = lh
    end
    new_height = lh*#self._lines
    if new_height > self._min_height then
        self._min_height = new_height
        self.height = new_height
        self._height = new_height
        return true
    end

    -- Special handling for first run
    if not self.width then
        return true
    end
    -- if new min is bigger then current request reflow
    if self._min_width > self.width or self._min_height > height then
        return true
    end
end

function ConkyText:render(cr)
    cairo_set_source_rgba(cr, unpack(self._color))
    for i, line in ipairs(self._render_lines) do
        local y = (i - 1) * self._line_height
        cairo_text_hp_show(cr, self._x, y, line, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
    end
end

--- Draw some unchangeable text.
-- Use this widget for text that will never be updated.Text
-- @type StaticText
local StaticText = util.class(Text)
w.StaticText = StaticText

--- @string text Text to be displayed.
-- @tparam ?table args table of options, see `Text:init`
function StaticText:init(text, args)
    Text.init(self, args or {})

    self._lines = {}
    text = text .. "\n"

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
--    print("text size B:", text, self._font_data, w, h, #self._lines * h)

end

function StaticText:render(cr)
    cairo_set_source_rgba(cr, unpack(self._color))
    for i, line in ipairs(self._lines) do
        local y = (i - 1) * self._line_height
        cairo_text_hp_show(cr, self._x, y, line, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
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
    self.height = self._line_height
    self.needs_rebuild = false
    self.width = 0
end

--- Update the text line to be displayed.
-- @string text
function TextLine:set_text(text)
    self._text = text

--    print("text size C:", text, self._font_data)
    local w, h = cairo_text_hp_text_size(self._text, self._font_family, self._font_size, 
                             self._font_direction, self._font_script, self._font_language)

    if w > self._min_width then
        self._min_width = w
        if w > self.width then
            self.needs_rebuild = true
        end
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
    cairo_text_hp_show(cr, self._x, y, self._text, self._font_family, self._font_size, self._align,
                             self._font_language, self._font_script, self._font_direction)
end


return w
