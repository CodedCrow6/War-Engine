#  jg_context.gd -*- mode: gdscript -*-
@tool
class_name jg_context
extends EditorPlugin
"""

"""
var fs_slot		= EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM
var fs_menu		= preload("context_menus/jg_fs_menu.gd").new()
var st_slot		= EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE
var scene_menu  = preload("context_menus/jg_scene_menu.gd").new()

const default_prefix = "res://addons/"
const default_groups = {
	"gd"		: "Scripts",
	"png"		: "Images",
	"res"		: "Godot",
	"scn"		: "Godot",
	"tres"		: "Godot",
	"tscn"		: "Godot",
	"ttf"		: "Fonts",
	}
const default_exclusions = "addons"
const default_debug = jg_utils.LOG_LEVEL.ERROR

func _enter_tree():
	print("Activating jg_asset_packer")
	register_editor_settings()
	initialise_values_from_settings()
	add_context_menu_plugin(fs_slot, fs_menu)
	add_context_menu_plugin(st_slot, scene_menu)

func _exit_tree():
	print("DeActivating jg_asset_packer")
	deregister_editor_settings()
	remove_context_menu_plugin(fs_menu)
	remove_context_menu_plugin(scene_menu)

func register_editor_settings():
	var editor_settings = EditorInterface.get_editor_settings()
	if editor_settings.has_setting(jg_utils.setting_named("Collection/Prefix")):
		print("Settings already set")
		return
	editor_settings.set_setting(jg_utils.setting_named("Collection/Prefix"), default_prefix)
	editor_settings.set_setting(jg_utils.setting_named("Collection/Exclusions"), default_exclusions)
	editor_settings.set_setting(jg_utils.setting_named("Collection/Groups"), default_groups)
	editor_settings.set_setting(jg_utils.setting_named("Debugging/Level"), default_debug)

	editor_settings.add_property_info({
		"name" : jg_utils.setting_named("Debugging/Level"),
		"type" : TYPE_INT,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string": jg_utils.LOG_LEVEL,
		})

	editor_settings.add_property_info({
		"name" : jg_utils.setting_named("Collection/Prefix"),
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_DIR,
		"hint_string": "The default addon name to use",
		})

	editor_settings.add_property_info({
		"name" : jg_utils.setting_named("Collection/Groups"),
		"type": TYPE_DICTIONARY,
		"hint_string" : "A dict mapping file extension to group name",
		})

	editor_settings.add_property_info({
		"name": jg_utils.setting_named("Collection/Exclusions"),
		"type": TYPE_STRING,
		"hint_string": "A comma separated list of path values which trigger a resource to be excluded from collection",
		})

func deregister_editor_settings():
		# EditorInterface.get_editor_settings().set_setting("", null)
	pass


func initialise_values_from_settings():
	var settings = EditorInterface.get_editor_settings()
	jg_utils.debug = settings.get_setting(jg_utils.setting_named("Debugging/Level"))
