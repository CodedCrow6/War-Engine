#  jg_scene_menu.gd -*- mode: gdscript -*-
@tool
class_name jg_scene_menu
extends JG_Base_Menu
"""

"""


var targets = []

func _popup_menu(paths: PackedStringArray):
	add_context_menu_item("Export as Addon", popup_export)

func popup_export(args):
	jg_utils.header("Exporting Nodes: %s" % args, Level.USER)
	targets = args
	var popup	= load("res://addons/jg_asset_packer/ui/jg_popup.tscn").instantiate()
	popup.addon_named.connect(export_addon)
	EditorInterface.popup_dialog_centered(popup)
	popup.set_resource_list({})

func export_addon(name, prefix, allowed, debug:Level=Level.USER):
	var prev_debug = jg_utils.debug
	jg_utils.debug			= debug
	jg_utils.reset_indent()
	jg_utils.set_prefix_and_target(prefix, name)

	handled				= []
	save_flags			= ResourceSaver.FLAG_NONE
	allow_overwrite		= true
	resource_whitelist  = allowed
	var as_path			= prefix.path_join(name)

	# Create a temp scene
	var target				= jg_utils.as_target("%s.tscn" % targets[0].name)
	var scene				= jg_utils.pack_scene(targets[0])
	scene.resource_path		= target

	jg_utils.msg("Target Addon Name: %s" % as_path, Level.USER)
	jg_utils.msg("Targets: %s" % targets, Level.USER)

	if not jg_utils.ensure_export_dir(prefix, name): pass
	save_resource(scene, scene.resource_path)
	assert(FileAccess.file_exists(target), "Scene doesnt exist: %s" % scene.resource_path)

	report_deps([ target ])
	copy_resource(target)
	report_handled()
	report_change([target])
	EditorInterface.get_resource_filesystem().scan()
	jg_utils.debug = prev_debug
	resource_whitelist.clear()
	jg_utils.header("Exported", Level.USER)
