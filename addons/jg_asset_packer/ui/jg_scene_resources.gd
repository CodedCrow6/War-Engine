@tool
extends Control
"""
Sets up the tree of resources to allow users to select what to collect.

TreeItem columns:
0: checkboxes, with meta_data = True if its a group heading
1: the title of the data/group
"""

const Level				= jg_utils.LOG_LEVEL

var total_count			= 0
var start_collapsed		= false
var baseDict			= {
	"Scenes"	: ["blah.tscn", "bloo.tscn"],
	"Scripts"	: ["something.gd", "aweg.gd"],
	"Textures"  : ["blah.tres", "bloo.png"],
	"Fonts"		: ["awjeigo.ttf"],
	}
var itemMap = {}

enum {TITEM_GROUP, TITEM_RESOURCE}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.list_resources(baseDict)
	$Tree.connect(&"item_activated", _on_tree_item_activated)
	connect(&"tree_exiting", collect_entries)
	pass

func setup_tree(keys:Array) -> void:
	$Tree.clear()
	self.itemMap.clear()
	self.total_count = 0
	if keys.is_empty():
		jg_utils.msg("Hiding", Level.DETAIL)
		self.visible = false

		return

	self.visible = true
	var tree = $Tree
	var root = tree.create_item()
	root.set_text(0, "Targeted:")

	tree.set_column_title(0, "Collect?")
	tree.set_column_title(1, "Resource")
	tree.set_column_expand(0, false)
	tree.set_column_expand(1, true)


	jg_utils.msg("Root: %s" % root, Level.TRACE)
	for cat in keys:
		if cat in self.itemMap:
			continue
		jg_utils.msg("Creating %s in %s" % [cat, root], Level.DETAIL)
		var node = tree.create_item(root)
		node.set_selectable(0, true)
		node.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		node.set_text(1, cat)
		node.set_metadata(0, TITEM_GROUP)
		node.set_collapsed_recursive(true)
		self.itemMap[cat] = node

func collect_entries() -> Array:
	var result  = []
	var root    = $Tree.get_root()
	assert(root, "No root for the tree found")
	for cat in root.get_children():
		result += cat.get_children().filter(func(elem): return elem.is_checked(0)).map(func(elem): return elem.get_metadata(1))

	jg_utils.msg("Collected: %s" % [result])
	result.sort()
	return result

func hide_entries() -> void:
	$Tree.get_root().set_collapsed(true)

func list_resources(theDict) -> void:
	""" theDict : [ name : [paths] ] """
	jg_utils.msg("Listing: %s" % theDict, Level.DETAIL)
	self.setup_tree(theDict.keys())
	var tree = $Tree
	assert(tree.get_root(), "No Root for the tree found")
	for val in theDict:
		var cat = self.itemMap[val]
		cat.set_collapsed_recursive(start_collapsed)
		self.add_entries(tree, cat, theDict[val])


	tree.set_column_title(1, "Resource (%s)" % self.total_count)
	for cat in tree.get_root().get_children():
		cat.set_text(1, "%s (%s)" % [ cat.get_text(1), len(cat.get_children()) ])

func add_entries(tree, curr, subList) -> void:
	for val in subList:
		var node = tree.create_item(curr)
		node.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		node.set_selectable(0, TITEM_RESOURCE)
		node.set_metadata(0, TITEM_RESOURCE)
		node.set_text(1, val.get_file())
		node.set_metadata(1, val)
		self.total_count += 1

func _on_tree_item_activated():
	var tree		= $Tree
	var item		= $Tree.get_selected()
	var checked		= item.is_checked(0)
	match item.get_metadata(0):
		TITEM_GROUP: # Check all sub-resources
			item.set_checked(0, not item.is_checked(0))
			for sub in item.get_children():
				sub.set_checked(0, item.is_checked(0))
		TITEM_RESOURCE:
			item.set_checked(0, not item.is_checked(0))
		_:
			print("Unknown: %s" % item)
			item.set_checked(0, not item.is_checked(0))

func _select_groups():
	var tree = $Tree
	assert(tree.get_root(), "No Root for the tree found")
	for cat in tree.get_root().get_children():
		cat.set_checked(0, true)
		cat.set_collapsed_recursive(true)
		for child in cat.get_children():
			child.set_checked(0, true)

func _exit_tree():
	itemMap.free()
