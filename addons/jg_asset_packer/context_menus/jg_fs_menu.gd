#  jg_context_memu.gd -*- mode: gdscript -*-
@tool
class_name jg_fs_menu
extends JG_Base_Menu
"""
A FileSystem context menu plugin

"""

var targets				= []

func _popup_menu(paths: PackedStringArray):
	# TODO if paths are scenes...
	add_context_menu_item("Export with Resources as Addon", popup_export)
	add_context_menu_item("Export as Zipped Addon", popup_zip)
	# add_context_menu_item("Testing", popup_testing)
	# add_context_menu_item("Bundle Resources as Addon", popup_bundle)
	add_context_menu_item("List Transitive Dependencies", do_describe)

func popup_testing(args):
	var settings = EditorInterface.get_editor_settings()
	var level = settings.get_setting(jg_utils.setting_named("Debugging/Level"))
	print("Debug Level: %s : %s" % [level, jg_utils.debug])

func popup_export(args):
	jg_utils.header("Exporting: %s" % args, Level.USER)
	targets		= args
	var popup	= load("res://addons/jg_asset_packer/ui/jg_popup.tscn").instantiate()

	popup.addon_named.connect(export_addon)
	EditorInterface.popup_dialog_centered(popup)

	# TODO pre-parse the resource and pass for selection?
	var resources = walk_resources(args)
	jg_utils.msg("resources: %s" % resources)
	popup.set_resource_list(resources)

func popup_zip(args):
	jg_utils.header("Exporting Zip: %s" % args, Level.USER)
	targets		= args
	var popup	= load("res://addons/jg_asset_packer/ui/jg_popup.tscn").instantiate()

	popup.addon_named.connect(export_zip)
	EditorInterface.popup_dialog_centered(popup)

	# TODO pre-parse the resource and pass for selection?
	var resources = walk_resources(args)
	jg_utils.msg("resources: %s" % resources)
	popup.set_resource_list(resources)

func popup_bundle(args):
	jg_utils.header("Bundling : %s" % args, Level.USER)
	targets		= args
	var popup	= load("res://addons/jg_asset_packer/ui/jg_popup.tscn").instantiate()
	popup.addon_named.connect(bundle_addon)
	EditorInterface.popup_dialog_centered(popup)
	popup.set_resource_list({})

func do_describe(args):
	var prev_debug = jg_utils.debug
	jg_utils.debug = Level.USER
	report_deps(args)
	jg_utils.debug = prev_debug

func export_addon(name, prefix, allow_these, debug:Level=Level.USER):
	jg_utils.reset_indent()
	jg_utils.set_prefix_and_target(prefix, name)
	var prev_debug		= jg_utils.debug
	jg_utils.debug		= debug

	handled				= []
	save_flags			= ResourceSaver.FLAG_NONE
	resource_whitelist  = allow_these
	var as_path			= prefix.path_join(name)

	jg_utils.msg("Target Addon Name: %s" % as_path, Level.USER)
	jg_utils.msg("Targets: %s" % [targets], Level.USER)
	jg_utils.msg("Whitelist: %s" % [resource_whitelist], Level.USER)

	if (not jg_utils.ensure_export_dir(prefix, name)): pass

	report_deps(targets)
	for x in targets:
		copy_resource(x)

	report_handled()
	report_change(targets)
	EditorInterface.get_resource_filesystem().scan()
	jg_utils.debug = prev_debug
	resource_whitelist.clear()
	jg_utils.header("Exported", Level.USER)

func export_zip(name, prefix, allow_these, debug:Level=Level.USER):
	export_addon(name, prefix, allow_these, debug)
	jg_utils.header("Zipping", Level.USER)
	var writer = ZIPPacker.new()
	match writer.open("res://%s.zip" % name):
		OK: pass
		var err:
			assert(false, "Opening Zip Failed: %s" % err)
			return

	var base = prefix.path_join(name)
	var dir = DirAccess.open(base)
	assert(dir.dir_exists("."))
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue

		var curr_path = base.path_join(file_name)
		print("Zipping: %s" % curr_path)
		writer.start_file(curr_path.trim_prefix("res://"))
		writer.write_file(FileAccess.get_file_as_bytes(curr_path))
		writer.close_file()
		file_name = dir.get_next()

	dir.list_dir_end()
	writer.close()
	jg_utils.header("Zipped", Level.USER)

func bundle_addon(name, prefix, allowed, debug:Level=Level.USER):
	jg_utils.reset_indent()
	var prev_debug = jg_utils.debug
	jg_utils.debug			= debug

	handled					= []
	save_flags				= ResourceSaver.FLAG_BUNDLE_RESOURCES
	var as_res				= prefix.path_join(name)

	if (not jg_utils.ensure_export_dir(prefix, name)): return
	jg_utils.msg("Target Addon Name: %s" % as_res, Level.USER)
	jg_utils.msg("Targets: %s" % targets, Level.USER)
	for x in targets:
		copy_resource(x)

	EditorInterface.get_resource_filesystem().scan()
	jg_utils.debug = prev_debug
