-- luacheck: globals std stds

-- This file contains a collection of all globals that should be available
-- in Lua files executed by conky 1.10+. It is used by the luacheck command.
--
-- Note that some globals aren't always available:
--   * Conky only defines some globals in the rc file passed to `conky -c`.
--     Conversely, the remaining globals are _not_ available in that file.
--     See examples/*.lua for a way to get around this.
--   * Globals defined by cairo and imlib2 are only available after
--     require("cairo") and require("imlib2") have been called at least once.
--
-- The set of globals defined here is up-to-date as of conky 1.11.6_pre.

-- custom globals defined by polycore
stds.polycore = {
    globals = {
        "DEBUG",
        "conky_setup",
        "conky_update_background"
        "conky_update",
    },
}

-- globals defined by conky
stds.conky = {
    read_globals = {
        "conky",  -- only in rc file
        "conky_build_arch",
        "conky_build_date",
        "conky_build_info",
        "conky_config",
        "conky_info",
        "conky_parse",
        "conky_set_update_interval",
        "conky_version",
        "conky_window",
        "tolua",
    },
}

-- globals defined by cairo
-- see https://www.cairographics.org/manual/
stds.cairo = {
    read_globals = {
        "CAIRO_ANTIALIAS_BEST",
        "CAIRO_ANTIALIAS_DEFAULT",
        "CAIRO_ANTIALIAS_FAST",
        "CAIRO_ANTIALIAS_GOOD",
        "CAIRO_ANTIALIAS_GRAY",
        "CAIRO_ANTIALIAS_NONE",
        "CAIRO_ANTIALIAS_SUBPIXEL",
        "cairo_append_path",
        "cairo_arc",
        "cairo_arc_negative",
        "cairo_clip",
        "cairo_clip_extents",
        "cairo_clip_preserve",
        "cairo_close_path",
        "CAIRO_CONTENT_ALPHA",
        "CAIRO_CONTENT_COLOR",
        "CAIRO_CONTENT_COLOR_ALPHA",
        "cairo_copy_clip_rectangle_list",
        "cairo_copy_page",
        "cairo_copy_path",
        "cairo_copy_path_flat",
        "cairo_create",
        "cairo_curve_to",
        "cairo_debug_reset_static_data",
        "cairo_destroy",
        "cairo_device_to_user",
        "cairo_device_to_user_distance",
        "CAIRO_EXTEND_NONE",
        "CAIRO_EXTEND_PAD",
        "CAIRO_EXTEND_REFLECT",
        "CAIRO_EXTEND_REPEAT",
        "cairo_fill",
        "cairo_fill_extents",
        "cairo_fill_preserve",
        "CAIRO_FILL_RULE_EVEN_ODD",
        "CAIRO_FILL_RULE_WINDING",
        "CAIRO_FILTER_BEST",
        "CAIRO_FILTER_BILINEAR",
        "CAIRO_FILTER_FAST",
        "CAIRO_FILTER_GAUSSIAN",
        "CAIRO_FILTER_GOOD",
        "CAIRO_FILTER_NEAREST",
        "cairo_font_extents",
        "cairo_font_extents_t",
        "cairo_font_face_destroy",
        "cairo_font_face_get_reference_count",
        "cairo_font_face_get_type",
        "cairo_font_face_get_user_data",
        "cairo_font_face_reference",
        "cairo_font_face_set_user_data",
        "cairo_font_face_status",
        "cairo_font_options_copy",
        "cairo_font_options_create",
        "cairo_font_options_destroy",
        "cairo_font_options_equal",
        "cairo_font_options_get_antialias",
        "cairo_font_options_get_hint_metrics",
        "cairo_font_options_get_hint_style",
        "cairo_font_options_get_subpixel_order",
        "cairo_font_options_hash",
        "cairo_font_options_merge",
        "cairo_font_options_set_antialias",
        "cairo_font_options_set_hint_metrics",
        "cairo_font_options_set_hint_style",
        "cairo_font_options_set_subpixel_order",
        "cairo_font_options_status",
        "CAIRO_FONT_SLANT_ITALIC",
        "CAIRO_FONT_SLANT_NORMAL",
        "CAIRO_FONT_SLANT_OBLIQUE",
        "CAIRO_FONT_TYPE_FT",
        "CAIRO_FONT_TYPE_QUARTZ",
        "CAIRO_FONT_TYPE_TOY",
        "CAIRO_FONT_TYPE_USER",
        "CAIRO_FONT_TYPE_WIN32",
        "CAIRO_FONT_WEIGHT_BOLD",
        "CAIRO_FONT_WEIGHT_NORMAL",
        "CAIRO_FORMAT_A1",
        "CAIRO_FORMAT_A8",
        "CAIRO_FORMAT_ARGB32",
        "CAIRO_FORMAT_RGB24",
        "cairo_format_stride_for_width",
        "cairo_get_antialias",
        "cairo_get_current_point",
        "cairo_get_dash",
        "cairo_get_dash_count",
        "cairo_get_fill_rule",
        "cairo_get_font_face",
        "cairo_get_font_matrix",
        "cairo_get_font_options",
        "cairo_get_group_target",
        "cairo_get_line_cap",
        "cairo_get_line_join",
        "cairo_get_line_width",
        "cairo_get_matrix",
        "cairo_get_miter_limit",
        "cairo_get_operator",
        "cairo_get_reference_count",
        "cairo_get_scaled_font",
        "cairo_get_source",
        "cairo_get_target",
        "cairo_get_tolerance",
        "cairo_get_user_data",
        "cairo_glyph_allocate",
        "cairo_glyph_extents",
        "cairo_glyph_free",
        "cairo_glyph_path",
        "cairo_glyph_t",
        "cairo_has_current_point",
        "CAIRO_HINT_METRICS_DEFAULT",
        "CAIRO_HINT_METRICS_OFF",
        "CAIRO_HINT_METRICS_ON",
        "CAIRO_HINT_STYLE_DEFAULT",
        "CAIRO_HINT_STYLE_FULL",
        "CAIRO_HINT_STYLE_MEDIUM",
        "CAIRO_HINT_STYLE_NONE",
        "CAIRO_HINT_STYLE_SLIGHT",
        "cairo_identity_matrix",
        "cairo_image_surface_create",
        "cairo_image_surface_create_for_data",
        "cairo_image_surface_create_from_png",
        "cairo_image_surface_create_from_png_stream",
        "cairo_image_surface_get_data",
        "cairo_image_surface_get_format",
        "cairo_image_surface_get_height",
        "cairo_image_surface_get_stride",
        "cairo_image_surface_get_width",
        "cairo_in_fill",
        "cairo_in_stroke",
        "CAIRO_LINE_CAP_BUTT",
        "CAIRO_LINE_CAP_ROUND",
        "CAIRO_LINE_CAP_SQUARE",
        "CAIRO_LINE_JOIN_BEVEL",
        "CAIRO_LINE_JOIN_MITER",
        "CAIRO_LINE_JOIN_ROUND",
        "cairo_line_to",
        "cairo_mask",
        "cairo_mask_surface",
        "cairo_matrix_init",
        "cairo_matrix_init_identity",
        "cairo_matrix_init_rotate",
        "cairo_matrix_init_scale",
        "cairo_matrix_init_translate",
        "cairo_matrix_invert",
        "cairo_matrix_multiply",
        "cairo_matrix_rotate",
        "cairo_matrix_scale",
        "cairo_matrix_t",
        "cairo_matrix_transform_distance",
        "cairo_matrix_transform_point",
        "cairo_matrix_translate",
        "cairo_move_to",
        "cairo_new_path",
        "cairo_new_sub_path",
        "CAIRO_OPERATOR_ADD",
        "CAIRO_OPERATOR_ATOP",
        "CAIRO_OPERATOR_CLEAR",
        "CAIRO_OPERATOR_COLOR_BURN",
        "CAIRO_OPERATOR_COLOR_DODGE",
        "CAIRO_OPERATOR_DARKEN",
        "CAIRO_OPERATOR_DEST",
        "CAIRO_OPERATOR_DEST_ATOP",
        "CAIRO_OPERATOR_DEST_IN",
        "CAIRO_OPERATOR_DEST_OUT",
        "CAIRO_OPERATOR_DEST_OVER",
        "CAIRO_OPERATOR_DIFFERENCE",
        "CAIRO_OPERATOR_EXCLUSION",
        "CAIRO_OPERATOR_HARD_LIGHT",
        "CAIRO_OPERATOR_HSL_COLOR",
        "CAIRO_OPERATOR_HSL_HUE",
        "CAIRO_OPERATOR_HSL_LUMINOSITY",
        "CAIRO_OPERATOR_HSL_SATURATION",
        "CAIRO_OPERATOR_IN",
        "CAIRO_OPERATOR_LIGHTEN",
        "CAIRO_OPERATOR_MULTIPLY",
        "CAIRO_OPERATOR_OUT",
        "CAIRO_OPERATOR_OVER",
        "CAIRO_OPERATOR_OVERLAY",
        "CAIRO_OPERATOR_SATURATE",
        "CAIRO_OPERATOR_SCREEN",
        "CAIRO_OPERATOR_SOFT_LIGHT",
        "CAIRO_OPERATOR_SOURCE",
        "CAIRO_OPERATOR_XOR",
        "cairo_paint",
        "cairo_paint_with_alpha",
        "CAIRO_PATH_CLOSE_PATH",
        "CAIRO_PATH_CURVE_TO",
        "cairo_path_destroy",
        "cairo_path_extents",
        "CAIRO_PATH_LINE_TO",
        "CAIRO_PATH_MOVE_TO",
        "cairo_path_t",
        "cairo_pattern_add_color_stop_rgb",
        "cairo_pattern_add_color_stop_rgba",
        "cairo_pattern_create_for_surface",
        "cairo_pattern_create_linear",
        "cairo_pattern_create_radial",
        "cairo_pattern_create_rgb",
        "cairo_pattern_create_rgba",
        "cairo_pattern_destroy",
        "cairo_pattern_get_color_stop_count",
        "cairo_pattern_get_color_stop_rgba",
        "cairo_pattern_get_extend",
        "cairo_pattern_get_filter",
        "cairo_pattern_get_linear_points",
        "cairo_pattern_get_matrix",
        "cairo_pattern_get_radial_circles",
        "cairo_pattern_get_reference_count",
        "cairo_pattern_get_rgba",
        "cairo_pattern_get_surface",
        "cairo_pattern_get_type",
        "cairo_pattern_get_user_data",
        "cairo_pattern_reference",
        "cairo_pattern_set_extend",
        "cairo_pattern_set_filter",
        "cairo_pattern_set_matrix",
        "cairo_pattern_set_user_data",
        "cairo_pattern_status",
        "CAIRO_PATTERN_TYPE_LINEAR",
        "CAIRO_PATTERN_TYPE_RADIAL",
        "CAIRO_PATTERN_TYPE_SOLID",
        "CAIRO_PATTERN_TYPE_SURFACE",
        "cairo_pop_group",
        "cairo_pop_group_to_source",
        "cairo_push_group",
        "cairo_push_group_with_content",
        "cairo_rectangle",
        "cairo_rectangle_list_destroy",
        "cairo_rectangle_list_t",
        "cairo_rectangle_t",
        "cairo_reference",
        "cairo_rel_curve_to",
        "cairo_rel_line_to",
        "cairo_rel_move_to",
        "cairo_reset_clip",
        "cairo_restore",
        "cairo_rotate",
        "cairo_save",
        "cairo_scale",
        "cairo_scaled_font_create",
        "cairo_scaled_font_destroy",
        "cairo_scaled_font_extents",
        "cairo_scaled_font_get_ctm",
        "cairo_scaled_font_get_font_face",
        "cairo_scaled_font_get_font_matrix",
        "cairo_scaled_font_get_font_options",
        "cairo_scaled_font_get_reference_count",
        "cairo_scaled_font_get_scale_matrix",
        "cairo_scaled_font_get_type",
        "cairo_scaled_font_get_user_data",
        "cairo_scaled_font_glyph_extents",
        "cairo_scaled_font_reference",
        "cairo_scaled_font_set_user_data",
        "cairo_scaled_font_status",
        "cairo_scaled_font_text_extents",
        "cairo_scaled_font_text_to_glyphs",
        "cairo_select_font_face",
        "cairo_set_antialias",
        "cairo_set_dash",
        "cairo_set_fill_rule",
        "cairo_set_font_face",
        "cairo_set_font_matrix",
        "cairo_set_font_options",
        "cairo_set_font_size",
        "cairo_set_line_cap",
        "cairo_set_line_join",
        "cairo_set_line_width",
        "cairo_set_matrix",
        "cairo_set_miter_limit",
        "cairo_set_operator",
        "cairo_set_scaled_font",
        "cairo_set_source",
        "cairo_set_source_rgb",
        "cairo_set_source_rgba",
        "cairo_set_source_surface",
        "cairo_set_tolerance",
        "cairo_set_user_data",
        "cairo_show_glyphs",
        "cairo_show_page",
        "cairo_show_text",
        "cairo_show_text_glyphs",
        "cairo_status",
        "CAIRO_STATUS_CLIP_NOT_REPRESENTABLE",
        "CAIRO_STATUS_FILE_NOT_FOUND",
        "CAIRO_STATUS_FONT_TYPE_MISMATCH",
        "CAIRO_STATUS_INVALID_CLUSTERS",
        "CAIRO_STATUS_INVALID_CONTENT",
        "CAIRO_STATUS_INVALID_DASH",
        "CAIRO_STATUS_INVALID_DSC_COMMENT",
        "CAIRO_STATUS_INVALID_FORMAT",
        "CAIRO_STATUS_INVALID_INDEX",
        "CAIRO_STATUS_INVALID_MATRIX",
        "CAIRO_STATUS_INVALID_PATH_DATA",
        "CAIRO_STATUS_INVALID_POP_GROUP",
        "CAIRO_STATUS_INVALID_RESTORE",
        "CAIRO_STATUS_INVALID_SLANT",
        "CAIRO_STATUS_INVALID_STATUS",
        "CAIRO_STATUS_INVALID_STRIDE",
        "CAIRO_STATUS_INVALID_STRING",
        "CAIRO_STATUS_INVALID_VISUAL",
        "CAIRO_STATUS_INVALID_WEIGHT",
        "CAIRO_STATUS_NEGATIVE_COUNT",
        "CAIRO_STATUS_NO_CURRENT_POINT",
        "CAIRO_STATUS_NO_MEMORY",
        "CAIRO_STATUS_NULL_POINTER",
        "CAIRO_STATUS_PATTERN_TYPE_MISMATCH",
        "CAIRO_STATUS_READ_ERROR",
        "CAIRO_STATUS_SUCCESS",
        "CAIRO_STATUS_SURFACE_FINISHED",
        "CAIRO_STATUS_SURFACE_TYPE_MISMATCH",
        "CAIRO_STATUS_TEMP_FILE_ERROR",
        "cairo_status_to_string",
        "CAIRO_STATUS_USER_FONT_ERROR",
        "CAIRO_STATUS_USER_FONT_IMMUTABLE",
        "CAIRO_STATUS_WRITE_ERROR",
        "cairo_stroke",
        "cairo_stroke_extents",
        "cairo_stroke_preserve",
        "CAIRO_SUBPIXEL_ORDER_BGR",
        "CAIRO_SUBPIXEL_ORDER_DEFAULT",
        "CAIRO_SUBPIXEL_ORDER_RGB",
        "CAIRO_SUBPIXEL_ORDER_VBGR",
        "CAIRO_SUBPIXEL_ORDER_VRGB",
        "cairo_surface_copy_page",
        "cairo_surface_create_similar",
        "cairo_surface_destroy",
        "cairo_surface_finish",
        "cairo_surface_flush",
        "cairo_surface_get_content",
        "cairo_surface_get_device_offset",
        "cairo_surface_get_fallback_resolution",
        "cairo_surface_get_font_options",
        "cairo_surface_get_reference_count",
        "cairo_surface_get_type",
        "cairo_surface_get_user_data",
        "cairo_surface_has_show_text_glyphs",
        "cairo_surface_mark_dirty",
        "cairo_surface_mark_dirty_rectangle",
        "cairo_surface_reference",
        "cairo_surface_set_device_offset",
        "cairo_surface_set_fallback_resolution",
        "cairo_surface_set_user_data",
        "cairo_surface_show_page",
        "cairo_surface_status",
        "CAIRO_SURFACE_TYPE_BEOS",
        "CAIRO_SURFACE_TYPE_DIRECTFB",
        "CAIRO_SURFACE_TYPE_GLITZ",
        "CAIRO_SURFACE_TYPE_IMAGE",
        "CAIRO_SURFACE_TYPE_OS2",
        "CAIRO_SURFACE_TYPE_PDF",
        "CAIRO_SURFACE_TYPE_PS",
        "CAIRO_SURFACE_TYPE_QUARTZ",
        "CAIRO_SURFACE_TYPE_QUARTZ_IMAGE",
        "CAIRO_SURFACE_TYPE_SVG",
        "CAIRO_SURFACE_TYPE_WIN32",
        "CAIRO_SURFACE_TYPE_WIN32_PRINTING",
        "CAIRO_SURFACE_TYPE_XCB",
        "CAIRO_SURFACE_TYPE_XLIB",
        "cairo_surface_write_to_png",
        "cairo_surface_write_to_png_stream",
        "cairo_text_cluster_allocate",
        "CAIRO_TEXT_CLUSTER_FLAG_BACKWARD",
        "cairo_text_cluster_free",
        "cairo_text_cluster_t",
        "cairo_text_extents",
        "cairo_text_extents_t",
        "cairo_text_path",
        "cairo_toy_font_face_create",
        "cairo_toy_font_face_get_family",
        "cairo_toy_font_face_get_slant",
        "cairo_toy_font_face_get_weight",
        "cairo_transform",
        "cairo_translate",
        "cairo_user_data_key_t",
        "cairo_user_font_face_create",
        "cairo_user_font_face_get_init_func",
        "cairo_user_font_face_get_render_glyph_func",
        "cairo_user_font_face_get_text_to_glyphs_func",
        "cairo_user_font_face_get_unicode_to_glyph_func",
        "cairo_user_font_face_set_init_func",
        "cairo_user_font_face_set_render_glyph_func",
        "cairo_user_font_face_set_text_to_glyphs_func",
        "cairo_user_font_face_set_unicode_to_glyph_func",
        "cairo_user_to_device",
        "cairo_user_to_device_distance",
        "cairo_version",
        "cairo_version_string",
        "cairo_xlib_surface_create",
        "cairo_xlib_surface_create_for_bitmap",
        "cairo_xlib_surface_get_depth",
        "cairo_xlib_surface_get_display",
        "cairo_xlib_surface_get_drawable",
        "cairo_xlib_surface_get_height",
        "cairo_xlib_surface_get_screen",
        "cairo_xlib_surface_get_visual",
        "cairo_xlib_surface_get_width",
        "cairo_xlib_surface_set_drawable",
        "cairo_xlib_surface_set_size",
    },
}

-- globals defined by imlib2
-- see https://docs.enlightenment.org/api/imlib2/html/imlib2_8c.html
stds.imlib = {
    read_globals = {
        "imlib_add_color_to_color_range",
        "imlib_add_path_to_font_path",
        "imlib_apply_color_modifier",
        "imlib_apply_color_modifier_to_rectangle",
        "imlib_blend_image_onto_image",
        "imlib_blend_image_onto_image_at_angle",
        "imlib_blend_image_onto_image_skewed",
        "imlib_clone_image",
        "imlib_context_get_angle",
        "imlib_context_get_anti_alias",
        "imlib_context_get_blend",
        "imlib_context_get_color",
        "imlib_context_get_color_cmya",
        "imlib_context_get_color_hlsa",
        "imlib_context_get_color_hsva",
        "imlib_context_get_color_modifier",
        "imlib_context_get_color_range",
        "imlib_context_get_direction",
        "imlib_context_get_dither",
        "imlib_context_get_dither_mask",
        "imlib_context_get_filter",
        "imlib_context_get_font",
        "imlib_context_get_image",
        "imlib_context_get_imlib_color",
        "imlib_context_get_mask_alpha_threshold",
        "imlib_context_get_operation",
        "imlib_context_get_progress_function",
        "imlib_context_get_progress_granularity",
        "imlib_context_set_angle",
        "imlib_context_set_anti_alias",
        "imlib_context_set_blend",
        "imlib_context_set_cliprect",
        "imlib_context_set_color",
        "imlib_context_set_color_cmya",
        "imlib_context_set_color_hlsa",
        "imlib_context_set_color_hsva",
        "imlib_context_set_color_modifier",
        "imlib_context_set_color_range",
        "imlib_context_set_direction",
        "imlib_context_set_dither",
        "imlib_context_set_dither_mask",
        "imlib_context_set_filter",
        "imlib_context_set_font",
        "imlib_context_set_image",
        "imlib_context_set_mask_alpha_threshold",
        "imlib_context_set_operation",
        "imlib_context_set_progress_function",
        "imlib_context_set_progress_granularity",
        "imlib_create_color_modifier",
        "imlib_create_color_range",
        "imlib_create_cropped_image",
        "imlib_create_cropped_scaled_image",
        "imlib_create_image",
        "imlib_create_image_using_copied_data",
        "imlib_create_image_using_data",
        "imlib_create_rotated_image",
        "imlib_flush_font_cache",
        "imlib_flush_loaders",
        "imlib_free_color_modifier",
        "imlib_free_color_range",
        "imlib_free_font",
        "imlib_free_font_list",
        "imlib_free_image",
        "imlib_free_image_and_decache",
        "imlib_get_cache_size",
        "imlib_get_color_modifier_tables",
        "imlib_get_color_usage",
        "imlib_get_font_ascent",
        "imlib_get_font_cache_size",
        "imlib_get_font_descent",
        "imlib_get_maximum_font_ascent",
        "imlib_get_maximum_font_descent",
        "imlib_get_next_font_in_fallback_chain",
        "imlib_get_prev_font_in_fallback_chain",
        "imlib_get_text_advance",
        "imlib_get_text_inset",
        "imlib_get_text_size",
        "imlib_image_attach_data_value",
        "imlib_image_blur",
        "imlib_image_clear",
        "imlib_image_copy_alpha_rectangle_to_image",
        "imlib_image_copy_alpha_to_image",
        "imlib_image_copy_rect",
        "imlib_image_draw_ellipse",
        "imlib_image_draw_line",
        "imlib_image_draw_polygon",
        "imlib_image_draw_rectangle",
        "imlib_image_fill_color_range_rectangle",
        "imlib_image_fill_ellipse",
        "imlib_image_fill_hsva_color_range_rectangle",
        "imlib_image_fill_polygon",
        "imlib_image_fill_rectangle",
        "imlib_image_flip_diagonal",
        "imlib_image_flip_horizontal",
        "imlib_image_flip_vertical",
        "imlib_image_format",
        "imlib_image_get_attached_data",
        "imlib_image_get_attached_value",
        "imlib_image_get_border",
        "imlib_image_get_data",
        "imlib_image_get_data_for_reading_only",
        "imlib_image_get_filename",
        "imlib_image_get_height",
        "imlib_image_get_width",
        "imlib_image_has_alpha",
        "imlib_image_orientate",
        "imlib_image_put_back_data",
        "imlib_image_query_pixel",
        "imlib_image_query_pixel_cmya",
        "imlib_image_query_pixel_hlsa",
        "imlib_image_query_pixel_hsva",
        "imlib_image_remove_and_free_attached_data_value",
        "imlib_image_remove_attached_data_value",
        "imlib_image_scroll_rect",
        "imlib_image_set_border",
        "imlib_image_set_changes_on_disk",
        "imlib_image_set_format",
        "imlib_image_set_has_alpha",
        "imlib_image_set_irrelevant_alpha",
        "imlib_image_set_irrelevant_border",
        "imlib_image_set_irrelevant_format",
        "imlib_image_sharpen",
        "imlib_image_tile",
        "imlib_image_tile_horizontal",
        "imlib_image_tile_vertical",
        "imlib_insert_font_into_fallback_chain",
        "imlib_list_font_path",
        "imlib_list_fonts",
        "imlib_load_font",
        "imlib_load_image",
        "imlib_load_image_immediately",
        "imlib_load_image_immediately_without_cache",
        "imlib_load_image_with_error_return",
        "imlib_load_image_without_cache",
        "imlib_modify_color_modifier_brightness",
        "imlib_modify_color_modifier_contrast",
        "imlib_modify_color_modifier_gamma",
        "imlib_polygon_add_point",
        "imlib_polygon_contains_point",
        "imlib_polygon_free",
        "imlib_polygon_get_bounds",
        "imlib_polygon_new",
        "imlib_remove_font_from_fallback_chain",
        "imlib_remove_path_from_font_path",
        "imlib_render_image_on_drawable",
        "imlib_reset_color_modifier",
        "imlib_save_image",
        "imlib_save_image_with_error_return",
        "imlib_set_cache_size",
        "imlib_set_color_modifier_tables",
        "imlib_set_color_usage",
        "imlib_set_font_cache_size",
        "imlib_text_draw",
        "imlib_text_draw_with_return_metrics",
        "imlib_text_get_index_and_location",
        "imlib_text_get_location_at_index",
        "imlib_update_append_rect",
        "imlib_updates_append_updates",
        "imlib_updates_clone",
        "imlib_updates_free",
        "imlib_updates_get_coordinates",
        "imlib_updates_get_next",
        "imlib_updates_init",
        "imlib_updates_merge",
        "imlib_updates_merge_for_rendering",
        "imlib_updates_set_coordinates",
    },
}

std = "min+polycore+conky+cairo+imlib"
