--- A collection of Container Widget classes
-- @module widget_container
-- @alias wc

pcall(function() require('cairo') end)
pcall(function() require('imlib2') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local text = require('src/widgets/text')
local Widget = core.Widget
local ConkyText, StaticText = text.ConkyText, text.StaticText

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

--- Basic collection of widgets.
-- Rows are drawn in a vertical stack starting at the top of the drawble
-- surface.
-- @type Rows
local Rows = util.class(Widget)
w.Rows = Rows

--- @tparam {Widget,...} widgets
function Rows:init(widgets)
    self._children = widgets

    local width = 0
    self._min_height = 0
    self._fillers = 0
    self._fixed_height = 0
    for _, widget in ipairs(self._children) do

        widget.parent = self

        if widget.width then
            if widget.width > width then width = widget.width end
        elseif widget._min_width then
            if widget._min_width > width then width = widget._min_width end
        end
        if widget.height ~= nil then
            self._min_height = self._min_height + widget.height
            self._fixed_height = self._fixed_height + widget.height
        elseif widget._min_height then
            self._min_height = self._min_height + widget._min_height
            self._fillers = self._fillers + 1
        else
            self._fillers = self._fillers + 1
        end
    end
    if self._fillers == 0 then
        self.height = self._min_height
    end
    self._min_width = width
end

function Rows:update(update_count)
    local reflow = false

    for _, widget in ipairs(self._children) do
        reflow = widget:update(update_count) or reflow
    end

    if reflow then
        local width = 0
        local new_min_height = 0
        self._fixed_height = 0
        self._fillers = 0
        for _, widget in ipairs(self._children) do

            widget.parent = self

            if widget.width then
                if widget.width > width then width = widget.width end
            elseif widget._min_width then
                if widget._min_width > width then width = widget._min_width end
            end
            if widget.height ~= nil then
                new_min_height = new_min_height + widget.height
                self._fixed_height = self._fixed_height + widget.height
            elseif widget._min_height then
                new_min_height = new_min_height + widget._min_height
                self._fillers = self._fillers + 1
            else
                self._fillers = self._fillers + 1
            end
        end
        if self._fillers == 0 then
            self.height = new_min_height
        end

        -- Design Decision, never shrink because it can look strange
        -- with dynamic content
        if width > self._min_width then
            self._min_width = width
        end
        if new_min_height > self._min_height then
            self._min_height = new_min_height
        end

        return true
    end
end

function Rows:layout(width, height)
    self._width = width  -- used to draw debug lines
    local y = 0
    local children = {}
    local filler_height = (height - self._fixed_height) / self._fillers

    -- Need to handle widgets that may have a min_height higher then the
    -- filler height, loop through until the same number of widgets with the
    -- that have larger min height is found twice, at that point the filler
    -- will be as small as it needs to be
    local last_count = -1
    local this_count = 0

    local actual_fillers = self._fillers
    local height_remaining = height - self._fixed_height

    while filler_height > 0 and last_count ~= this_count do
        last_count = this_count
        this_count = 0
        for _, widget in ipairs(self._children) do
            if widget._min_height then
                if widget._min_height > filler_height then
                    this_count = this_count + 1
                    actual_fillers = actual_fillers + 1
                    height_remaining = height_remaining - widget._min_height
                end
            end
        end
        filler_height = height_remaining / actual_fillers

        if filler_height < 0 then
            filler_height = 0
        end
    end
    for _, widget in ipairs(self._children) do
        local widget_height = filler_height
        if widget.height then
            widget_height = widget.height
        elseif widget._min_height then
            if widget._min_height > filler_height then
                widget_height = widget._min_height
            end
        end
        table.insert(children, {widget, 0, y, width, widget_height})
        local sub_children = widget:layout(width, widget_height) or {}
        for _, child in ipairs(sub_children) do
            child[3] = child[3] + y
            table.insert(children, child)
        end
        y = y + widget_height
    end
    return children
end

--- Display Widgets side by side
-- @type Columns
local Columns = util.class(Widget)
w.Columns = Columns

-- reuse an identical function

--- @tparam {Widget,...} widgets
function Columns:init(widgets)
    self._children = widgets

    self._min_width = 0
    self._fillers = 0
    self._fixed_width = 0
    local height = 0
    local fix_height = false
    for _, widget in ipairs(self._children) do
        widget.parent = self

        if widget.width ~= nil then
            self._min_width = self._min_width + widget.width
            self._fixed_width  = self._fixed_width + widget.width
        elseif widget._min_width then
            self._min_width = self._min_width + widget._min_width
            self._fillers = self._fillers + 1
        else
            self._fillers = self._fillers + 1
        end
        if widget.height then
            fix_height = true
            if widget.height > height then height = widget.height end
        elseif widget._min_height then
            if widget._min_height > height then height = widget._min_height end
        end
    end
    if self._fillers == 0 then
        self.width = self._min_width
    end
    if fix_height then
        self.height = height
    end
    self._min_height = height
end

function Columns:update(update_count)
    local reflow = false

    for _, widget in ipairs(self._children) do
        reflow = widget:update(update_count) or reflow
    end

    if reflow then
        self._fillers = 0
        self._fixed_width = 0
        local new_min_width = 0
        local height = 0
        local fix_height = false
        for _, widget in ipairs(self._children) do
            if widget.width ~= nil then
                new_min_width = new_min_width + widget.width
                self._fixed_width = self._fixed_width + widget.width
            elseif widget._min_width then
                new_min_width = new_min_width + widget._min_width
                self._fillers = self._fillers + 1
            else
                self._fillers = self._fillers + 1
            end
            if widget.height then
                fix_height = true
                if widget.height > height then height = widget.height end
            elseif widget._min_height then
                if widget._min_height > height then height = widget._min_height end
            end
        end
        if self._fillers == 0 then
            self.width = new_min_width
        end
        if fix_height then
            self.height = height
        end

        -- Design Decision, never shrink because it can look strange
        -- with dynamic content
        if new_min_width > self._min_width then
            self._min_width = new_min_width
        end
        if height > self._min_height then
            self._min_height = height
        end

        return true
    end
end

function Columns:layout(width, height)
    self._height = height  -- used to draw debug lines
    local x = 0
    local children = {}
    local filler_width = (width - self._fixed_width) / self._fillers

    -- Need to handle widgets that may have a min_height higher then the
    -- filler height, loop through until the same number of widgets with the
    -- that have larger min height is found twice, at that point the filler
    -- will be as small as it needs to be
    local last_count = -1
    local this_count = 0

    local actual_fillers = self._fillers
    local width_remaining = width - self._fixed_width

    while filler_width > 0 and last_count ~= this_count do

        last_count = this_count
        this_count = 0
        for _, widget in ipairs(self._children) do
            if widget._min_width then
                if widget._min_width > filler_width then
                    this_count = this_count + 1
                    actual_fillers = actual_fillers + 1
                    width_remaining = width_remaining - widget._min_width
                end
            end
        end
        filler_width = width_remaining / actual_fillers

        if filler_width < 0 then
            filler_width = 0
        end
    end

    for _, widget in ipairs(self._children) do
        local widget_width = filler_width
        if widget.width then
            widget_width = widget.width
        elseif widget._min_width then
            if widget._min_width > filler_width then
                widget_width = filler_width
            end
        end
        table.insert(children, {widget, x, 0, widget_width, height})
        local sub_children = widget:layout(widget_width, height) or {}
        for _, child in ipairs(sub_children) do
            child[2] = child[2] + x
            table.insert(children, child)
        end
        x = x + widget_width
    end
    return children
end

--- Display Widgets on top of each other
-- @type Stack
local Stack = util.class(Widget)
w.Stack = Stack

-- reuse an identical function

--- @tparam {Widget,...} widgets
function Stack:init(widgets)
    self._children = widgets

    self._min_width = 0
    self._min_height = 0

    for _, widget in ipairs(self._children) do
        widget.parent = self

        if widget.width ~= nil then
            if widget.width > self._min_width then
                self._min_width = widget.width
            end
        elseif widget._min_width then
            if widget._min_width > self._min_width then
                self._min_width = widget._min_width
            end
        end
        if widget.height then
            if widget.height > self._min_height then self._min_height = widget.height end
        elseif widget._min_height then
            if widget._min_height > self._min_height then self._min_height = widget._min_height end
        end
    end
end

function Stack:update(update_count)
    local reflow = false

    for _, widget in ipairs(self._children) do
        reflow = widget:update(update_count) or reflow
    end

    if reflow then
        self._fillers = 0
        self._fixed_width = 0
        local new_min_width = 0
        local new_min_height = 0
        for _, widget in ipairs(self._children) do
            widget.parent = self

            if widget.width ~= nil then
                if widget.width > new_min_width then
                    new_min_width = widget.width
                end
            elseif widget._min_width then
                if widget._min_width > new_min_width then
                    new_min_width = widget._min_width
                end
            end
            if widget.height then
                if widget.height > new_min_height then new_min_height = widget.height end
            elseif widget._min_height then
                if widget._min_height > new_min_height then new_min_height = widget._min_height end
            end
        end

        -- Design Decision, never shrink because it can look strange
        -- with dynamic content
        if new_min_width > self._min_width then
            self._min_width = new_min_width
        end
        if new_min_height > self._min_height then
            self._min_height = new_min_height
        end

        return true
    end
end

function Stack:layout(width, height)
    self._height = height  -- used to draw debug lines
    self._width = width
    local children = {}

    for _, widget in ipairs(self._children) do
        local x = 0
        local y = 0
        local width = self._width
        local height = self._height
        if widget.width then
            x = (self._width - widget.width) / 2
            width = widget.width
        elseif widget._min_width then
            -- If min_width then widget can expand to full size
            x = 0
            width = self._width
        end
        if widget.height then
            y = (self._height - widget.height) / 2
            height = widget.height
        elseif widget._min_height then
            -- If min_width then widget can expand to full size
            y = 0
            height = self._height
        end
        table.insert(children, {widget, x, y, width, height})
        local sub_children = widget:layout(width, height) or {}
        for _, child in ipairs(sub_children) do
            table.insert(children, child)
        end
    end
    return children
end

--- Hardcode a widget's location
-- @type Float
local Float = util.class(Widget)
w.Float = Float

-- reuse an identical function

--- @tparam ?Widget widget Inner widget, note that this object can only have one inner widget
--- @tparam ?table args table of options
-- @tparam @int args.x x offset
-- @tparam @int args.y y offset
-- @tparam @int args.width width of inner widget
-- @tparam @int args.height height of inner widget
function Float:init(widget, args)
    self._child = widget
    self._children = {self._child}
    widget.parent = self

    self._inner_x = args.x or 0
    self._inner_y = args.y or 0
    self._inner_width = args.width
    self._inner_height = args.height

    -- If the inner height / width is set we should hard code them.
    if self._inner_width ~= nil then
        self._width = self._inner_x + self._inner_width
    else
        if self._child.width ~= nil then
            if self._inner_width ~= nil then
                self._width = self._inner_x + self._inner_width + self._child.width
            else
                self._width = self._inner_x + self._child.width
            end
        elseif self._child._min_width then
            if self._inner_width ~= nil then
                self._min_width = self._inner_x + self._inner_width + self._child._min_width
            else
                self._min_width = self._inner_x + self._child._min_width
            end
        else
            if self._inner_width ~= nil then
                self._min_width = self._inner_x + self._inner_width
            end
        end
    end
    if self._inner_height ~= nil then
        self._height = self._inner_y + self._inner_height
    else
        if self._child.height ~= nil then
            if self._inner_height ~= nil then
                self.height = self._inner_y + self._inner_height + self._child.height
            else
                self.height = self._inner_y + self._child.height
            end
        elseif self._child._min_width then
            if self._inner_height ~= nil then
                self._min_height = self._inner_y + self._inner_height + self._child._min_height
            else
                self._min_height = self._inner_y + self._child._min_height
            end
        else
            if self._inner_height ~= nil then
                self._min_height = self._inner_y + self._inner_height
            end
        end
    end
end

function Float:update(update_count)
    local reflow = self._child:update(update_count)

    local new_min_width = nil
    local new_min_height = nil

    if reflow then
        if self._inner_width ~= nil then
            self._width = self._inner_x + self._inner_width
        else
            if self._child.width ~= nil then
                self._width = self._inner_x + self._child.width
            elseif self._child._min_width then
                new_min_width = self._inner_x  + self._child._min_width
            else
                if self._inner_width ~= nil then
                    new_min_width = self._inner_x + self._inner_width
                end
            end
            -- Design Decision, never shrink because it can look strange
            -- with dynamic content
            if new_min_width ~= nil then
                if new_min_width > self._min_width then
                    self._min_width = new_min_width
                end
            end
        end
        if self._inner_height ~= nil then
            self._height = self._inner_y + self._inner_height
        else
            if self._child.height ~= nil then
                self.height = self._inner_y + self._child.height
            elseif self._child._min_width then
                new_min_height = self._inner_y + self._child._min_height
            else
                if self._inner_height ~= nil then
                    new_min_height = self._inner_y + self._inner_height
                end
            end


            if self._min_height ~= nil then
                if new_min_height > self._min_height then
                    self._min_height = new_min_height
                end
            end
        end

        return true
    end
end

function Float:layout(width, height)
    self._height = height  -- used to draw debug lines
    self._width = width
    local children = {}

    local w = 0
    local h = 0

    if self._inner_width ~= nil then
        w = self._inner_width - self._inner_x
    else
        w = width - self._inner_x
    end

    if self._inner_height ~= nil then
        h = self._inner_height - self._inner_y
    else
        h = height - self._inner_y
    end

    table.insert(children, {self._child, self._inner_x, self._inner_y, w, h})
    local sub_children = self._child:layout(w, h) or {}
    for _, child in ipairs(sub_children) do
        child[2] = child[2] + self._inner_x
        child[3] = child[3] + self._inner_y
        table.insert(children, child)
    end
    return children
end

--- Leave space between widgets.
-- If either height or width is not specified, the available space
-- inside a Rows or Columns widget will be distributed evenly between Fillers
-- with no fixed height/width.
-- A Filler may contain one other Widget which will have its dimensions
-- restricted to those of the Filler.
-- @type Filler
local Filler = util.class(Widget)
w.Filler = Filler

--- @tparam ?table args table of options
-- @tparam ?int args.width
-- @tparam ?int args.height
-- @tparam ?Widget args.widget
function Filler:init(args)
    if args then
        self._widget = args.widget
        self.height = args.height or (self._widget and self._widget.height)
        self.width = args.width or (self._widget and self._widget.width)
    end

    if self._widget then
        self._widget.parent = self
    end
end

function Filler:layout(width, height)
    local children = {}

    if self._widget then
        table.insert(children, 1, {self._widget, 0, 0, width, height})

        local sub_children = self._widget:layout(width, height) or {}
        for _, child in ipairs(sub_children) do
            table.insert(children, child)
        end
        return children
    end
end


local function side_widths(arg)
    local arg = arg or 0
    if type(arg) == "number" then
        return {top=arg, right=arg, bottom=arg, left=arg}
    elseif #arg == 2 then
        return {top=arg[1], right=arg[2], bottom=arg[1], left=arg[2]}
    elseif #arg == 3 then
        return {top=arg[1], right=arg[2], bottom=arg[3], left=arg[2]}
    elseif #arg == 4 then
        return {top=arg[1], right=arg[2], bottom=arg[3], left=arg[4]}
    end
end


--- Draw a static border and/or background around/behind another widget.
-- @type Frame
local Frame = util.class(Widget)
w.Frame = Frame

-- @tparam Widget widget Widget to be wrapped
-- @tparam table args table of options
-- @tparam ?number|{number,...} args.padding Leave some space around the inside
--  of the frame.<br>
--  - number: same padding all around.<br>
--  - table of two numbers: {top & bottom, left & right}<br>
--  - table of three numbers: {top, left & right, bottom}<br>
--  - table of four numbers: {top, right, bottom, left}
-- @tparam ?number|{number,...} args.margin Like padding but outside the border.
-- @tparam ?{number,number,number,number} args.background_color
-- @tparam ?{string} args.background_image path to background image
-- @tparam [opt=1.0] ?number args.background_image_alpha alpha of the image between 0.0 and 1.0
-- @tparam[opt=transparent] ?{number,number,number,number} args.border_color
-- @tparam[opt=0] ?number args.border_width border line width
-- @tparam ?{string,...} args.border_sides any combination of
--                                         "top", "right", "bottom" and/or "left"
--                                         (default: all sides)
-- @tparam[opt=false] ?bool args.expand if true the frame will expand to the full space provided rather then just the space of the widget
function Frame:init(widget, args)
    self._child = widget
    widget.parent = self
    self._children = {widget}

    self._background_color = nil
    if args.background_color then
        self._background_color = ch.convert_string_to_rgba(args.background_color)
    end
    self._background_image = args.background_image or nil
    self._background_image_alpha = args.background_image_alpha or 1.0
    self._border_color = args.border_color or {0, 0, 0, 0}
    self._border_width = args.border_width or 0

    self._expand = args.expand or false

    self._padding = side_widths(args.padding)
    self._margin = side_widths(args.margin)
    self._border_sides = util.set(args.border_sides or {"top", "right", "bottom", "left"})

    self._has_background = self._background_color
    self._has_background_image = self._background_image
    self._has_border = self._border_width > 0
                       and (not args.border_sides or #args.border_sides > 0)

    self._x_left = self._margin.left + self._padding.left
                   + (self._border_sides.left and self._border_width or 0)
    self._y_top = self._margin.top + self._padding.top
                  + (self._border_sides.top and self._border_width or 0)
    self._x_right = self._margin.right + self._padding.right
                    + (self._border_sides.right and self._border_width or 0)
    self._y_bottom = self._margin.bottom + self._padding.bottom
                     + (self._border_sides.bottom and self._border_width or 0)

    if self._has_background_image then
        -- use imlib2 to calc background image size
        local imlib2img = imlib_load_image(self._background_image)
        if self._background_image == nil then
            self._has_background_image = false
            print("Error: Bubbles Frame: Couldn't load background image"..self._background_image)
        else
            imlib_context_set_image(imlib2img)
            self._background_image_width = imlib_image_get_width()
            self._background_image_height = imlib_image_get_height()
            imlib_free_image()
        end
    end
    if widget.width and self._expand ~= true then
        self.width = widget.width + self._x_left + self._x_right
    else
        local widget_min_w = self._child._min_width or 0
        self._min_width = widget_min_w + self._x_left + self._x_right
    end
    if widget.height and self._expand ~= true then
        self.height = widget.height + self._y_top + self._y_bottom
    else
        local widget_min_h = self._child._min_height or 0
        self._min_height = widget_min_h + self._y_top + self._y_bottom
    end
end

function Frame:update(update_count)
    local reflow = false
    reflow = self._child:update(update_count) or reflow

    if reflow then
        if self._child.width and self._expand ~= true then
            self.width = self._child.width + self._x_left + self._x_right
        else
            local widget_min_w = self._child._min_width or 0
            self._min_width = widget_min_w + self._x_left + self._x_right
        end
        if self._child.height and self._expand ~= true then
            self.height = self._child.height + self._y_top + self._y_bottom
        else
            local widget_min_h = self._child._min_height or 0
            self._min_height = widget_min_h + self._y_top + self._y_bottom
        end
        return true
    end
end

function Frame:layout(width, height)
    local children = {}

    self._width = width - self._margin.left - self._margin.right
    self._height = height - self._margin.top - self._margin.bottom
    local inner_width = width - self._x_left - self._x_right
    local inner_height = height - self._y_top - self._y_bottom
    table.insert(children, {self._child, self._x_left, self._y_top, inner_width, inner_height})
    local sub_children = self._child:layout(inner_width, inner_height) or {}

    for _, child in ipairs(sub_children) do
        child[2] = child[2] + self._x_left
        child[3] = child[3] + self._y_top
        table.insert(children, child)
    end
    return children
end

function Frame:render_background(cr)
    
    local w = self._width - self._margin.left - self._margin.right
    local h = self._height - self._margin.top - self._margin.bottom

    if self._has_background_image then
        cairo_place_image(self._background_image, cr, self._margin.left, self._margin.top, w, h, self._background_image_alpha)
    elseif self._has_background then
        cairo_rectangle(cr, self._margin.left, self._margin.top, w, h)
        cairo_set_source_rgba(cr, unpack(self._background_color))
        cairo_fill(cr)
    end

    if self._has_border then
        cairo_set_antialias(cr, CAIRO_ANTIALIAS_NONE)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_SQUARE)
        cairo_set_source_rgba(cr, unpack(self._border_color))
        cairo_set_line_width(cr, self._border_width)
        local x_min = self._margin.left + 0.5 * self._border_width
        local y_min = self._margin.top + 0.5 * self._border_width
        local x_max = self._margin.left + w - 0.5 * self._border_width
        local y_max = self._margin.top + h - 0.5 * self._border_width
        local side, line, move = self._border_sides, cairo_line_to, cairo_move_to
        cairo_move_to(cr, x_min, y_min);
        (side.top and line or move)(cr, x_max, y_min);
        (side.right and line or move)(cr, x_max, y_max);
        (side.bottom and line or move)(cr, x_min, y_max);
        (side.left and line or move)(cr, x_min, y_min);
        cairo_stroke(cr, self._background_color)
    end
end


--- Draw a "Block" With header, secondary header and widgets for content
-- @type Block
local Block = util.class(Frame)
w.Block = Block
-- @string header_text text for the heading
-- @string secondary_text text for right hand side, supports conky variables
-- @tparam {Widget,...} widgets for block body
-- @tparam table args table of options
-- @tparam ?number args.spacing the space between header and main content
-- @tparam ?number|{number,...} args.padding Leave some space around the inside
--  of the frame.<br>
--  - number: same padding all around.<br>
--  - table of two numbers: {top & bottom, left & right}<br>
--  - table of three numbers: {top, left & right, bottom}<br>
--  - table of four numbers: {top, right, bottom, left}
-- @tparam ?number|{number,...} args.margin Like padding but outside the border.
-- @tparam ?{number,number,number,number} args.background_color
-- @tparam ?{string} args.background_image path to background image
-- @tparam [opt=1.0] ?number args.background_image_alpha alpha of the image between 0.0 and 1.0
-- @tparam[opt=transparent] ?{number,number,number,number} args.border_color
-- @tparam[opt=0] ?number args.border_width border line width
-- @tparam ?{string,...} args.border_sides any combination of
--                                         "top", "right", "bottom" and/or "left"
--                                         (default: all sides)
function Block:init(header_text, secondary_text, widgets, args)
    self._spacing = args.spacing or 0

    local top_row = nil

    if secondary_text ~= "" then
        local stat_font = {align=CAIRO_TEXT_ALIGN_RIGHT}
        stat_font = util.merge_table(stat_font, current_theme.status_font)
        top_row = Columns{StaticText(header_text, current_theme.header_font), Filler{}, ConkyText(secondary_text, stat_font)}
    else
        top_row = StaticText(header_text, current_theme.header_font)
    end

    local main_widget = Rows{top_row, Filler{height=self._spacing}, unpack(widgets)}

    Frame.init(self, main_widget, args)

end

return w