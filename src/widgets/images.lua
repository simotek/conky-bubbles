--- A collection of Image classes
-- @module widget_image
-- @alias wi

pcall(function() require('cairo') end)
pcall(function() require('imlib2') end)
pcall(function() require('cairo_imlib2_helper') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local Widget = core.Widget

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table
local floor, ceil, clamp = math.floor, math.ceil, util.clamp


--- Common (abstract) base class for `StaticImage` and `Whatever Else`.
-- @type Image
local Image = util.class(Widget)
w.Image = Image
function Image:init(args)
    assert(getmetatable(self) ~= Image, "Cannot instanciate class Image directly.")
end

function Image:layout(width, height)
    self.width = width
    self.height = height
end
--- Draw an unchangeable image.
-- Use this widget for images that will never be updated.
-- @type Image
local StaticImage = util.class(Widget)
w.StaticImage = StaticImage

--- @string path image to be displayed.
-- @tparam ?table args table of options, see `Image:init`
function StaticImage:init(path, args)
    Image.init(self, args or {})

    self._path = path

    -- use imlib to find image size
    self._image = imlib_load_image(self._path)
    imlib_context_set_image(self._image)
    self._image_width = imlib_image_get_width()
    self._image_height = imlib_image_get_height()

    self._min_width = self._image_width
    self._min_height = self._image_height
end

function StaticImage:layout(width, height)
    self.width = width
    self.height = height
end

function StaticImage:render(cr)
    if self._image == nil then return end

    scale_width = self.width/self._image_width
    scale_height = self.height/self._image_height

    -- Scale by the larger ammount (smaller number) to maintain aspect ratio
    scale = 1.0
    if scale_width < scale_height then
        scale = scale_width
    else
        scale = scale_height
    end
    -- If scale is greater then 1 center rather then expand, in the future
    -- this could be an option
    x=0
    y=0
    if scale > 1.0 then
        x = (self.width-self._image_width)/2
        y = (self.height-self._image_height)/2
        scale = 1.0
    end
    cairo_draw_image(self._path, cairo_get_target(cr), x, y, scale, scale)
end

return w
