--- A Wrapper collection for all the widgets
-- @module widget
-- @alias w

local widgets = {}

widgets.core  = require('src/widgets/core')
widgets.containers  = require('src/widgets/containers')
widgets.cpu   = require('src/widgets/cpu')
widgets.drive = require('src/widgets/drive')
widgets.gpu   = require('src/widgets/gpu')
widgets.images = require('src/widgets/images')
widgets.mem   = require('src/widgets/memory')
widgets.net   = require('src/widgets/network')
widgets.text  = require('src/widgets/text')

return widgets