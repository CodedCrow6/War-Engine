#  naming.gd -*- mode: gdscript -*-
@tool
class_name JGPopup
extends ConfirmationDialog
"""

TODO: allow selection of types to copy/exclude
"""

const Level = jg_utils.LOG_LEVEL

static var default_name		: String	= "MyCollectedAddon"
static var default_prefix	: String	= EditorInterface.get_editor_settings().get_setting(jg_utils.setting_named("Collection/Prefix"))
static var default_debug	: Level     = EditorInterface.get_editor_settings().get_setting(jg_utils.setting_named("Debugging/Level"))

signal addon_named(text:String, prefix:String, allowed:Array[String], debug:jg_utils.LOG_LEVEL)

var baseDict = {
	"Scenes"	: [],
	"Scripts"	: [],
	"Textures"  : [],
	"Fonts"		: [],
	}

func _init():
	close_requested.connect(hide)
	confirmed.connect(complete)

func _ready() -> void:
	# TODO: if name already exists in prefix, adjust it
	$control/name/value.placeholder_text	= default_name
	$control/prefix/value.placeholder_text  = default_prefix
	$control/debug/value.value				= EditorInterface.get_editor_settings().get_setting(jg_utils.setting_named("Debugging/Level"))
	$control/SceneResources.list_resources(baseDict)

func set_resource_list(theDict) -> void:
	jg_utils.msg("Setting: %s" % theDict, Level.DETAIL)
	$control/SceneResources.list_resources(theDict)
	$control/SceneResources._select_groups()

func complete():
	var debug	= $control/debug/value.value
	match $control/prefix/value.text:
		"": pass
		var prefix:
			default_prefix  = prefix

	match $control/name/value.text:
		"": pass
		var text:
			default_name = text

	var allowed = $control/SceneResources.collect_entries()

	jg_utils.msg("Values: %s : %s : %s" % [default_prefix.path_join(default_name), allowed, debug], Level.DETAIL)
	addon_named.emit(
		default_name,
		default_prefix,
		allowed,
		debug,
		)

	close_requested.emit()
