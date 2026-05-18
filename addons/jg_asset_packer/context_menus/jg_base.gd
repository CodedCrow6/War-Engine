#  jg_base.gd -*- mode: gdscript-ts -*-
@tool
class_name JG_Base_Menu
extends EditorContextMenuPlugin
"""

TODO on export, reparse scripts and modify and 'extends "res://..." lines
TODO when copying, if the target already exists, load and return that instead, *not* return arg
"""

const Level				= jg_utils.LOG_LEVEL
const export_relative	= false
const cache_mode		= ResourceLoader.CACHE_MODE_IGNORE_DEEP
const exclusions		= ["Node", "Process", "Thread Group", "Physics Interpolation",  "owner",  "multiplayer"]
const mod_name			= "%s-coll"
var registered_groups	= EditorInterface.get_editor_settings().get_setting(jg_utils.setting_named("Collection/Groups"))
var allow_overwrite		= true
var save_flags			= ResourceSaver.FLAG_NONE
var handled				= []
var resource_whitelist  = []
var skip_dirs			= "addons"

#  report --------------------------------------------------

func report_handled():
	print("\n-- Handled (%s): " % len(handled))
	for x in handled:
		print("- %s (%s)" % [x, type_string(typeof(x))])

	print()

func report_deps(args, header:=true): # str -> None
	registered_groups	= EditorInterface.get_editor_settings().get_setting(jg_utils.setting_named("Collection/Groups"))
	assert(registered_groups, "No registered groups")
	var Log_At = Level.USER
	var deps = walk_resources(args)
	jg_utils.header("Deps of %s:" % [args], Log_At)
	for key in deps:
		jg_utils.msg("---- %s (%s):" % [key, len(deps[key])], Log_At)
		for val in deps[key]:
			jg_utils.msg("- %s" % val, Log_At)

func report_change(args):
	for arg in args:
		var target			= jg_utils.as_target(arg)
		var orig			= ResourceUID.path_to_uid(arg)
		var copied			= ResourceUID.path_to_uid(target)
		var orig_deps		= ResourceLoader.get_dependencies(arg)
		var copied_deps		= ResourceLoader.get_dependencies(target)
		assert(len(orig_deps) == len(copied_deps), "Deps differ: %s / %s" % [orig_deps, copied_deps])

		print("---- Change: %s -> %s" % [orig, copied])
		for i in range(len(orig_deps)):
			var left = orig_deps[i]
			var right = copied_deps[i]
			if left == right:
				print("==. %s == %s" % [left, right])
			else:
				print("||. %s || %s" % [left, right])

		# compare_trees(arg)

		print("---- Change: %s -> %s, %s -> %s" % [orig, copied, arg, target])

func compare_trees(arg):
	var target		= jg_utils.as_target(arg)
	var orig_ids	= []
	var copied_ids  = []
	var shared		= []

	for x in ResourceLoader.load(arg).instantiate().find_children("*"):
		orig_ids.append(x.get_instance_id())

	for x in ResourceLoader.load(target).instantiate().find_children("*"):
		copied_ids.append(x.get_instance_id())

	for i in range(len(orig_ids)):
		if orig_ids[i] in copied_ids:
			shared.append(orig_ids[i])

	if shared.is_empty():
		print("No shared ids")
		return

	print("Shared Ids:")
	for x in shared:
		print("- %s" % x)

func inspect_props(args):
	var prev_debug = jg_utils.debug
	jg_utils.debug = Level.DETAIL
	jg_utils.header("Props of: %s [%s]" % [args[0], args[0].get_instance_id()], Level.TRACE)

	var target			= args[0]
	var all_props       = target.get_property_list()
	var max				= len(all_props)
	var copy_props			= get_copy_props(target).map(func(elem): return elem.name)
	jg_utils.imsg("Prop Count: %s" % max)
	enter_copy(target)
	for i in range(max):
		var x = all_props[i]
		match target.get(x.name):
			0, null, "":
				jg_utils.imsg("Null   ... %s" % x.name, Level.DETAIL)
			var val when x.name == "script":
				jg_utils.imsg("Script ... %s" % val, Level.TRACE)
				for prop in val.get_script_property_list():
					jg_utils.imsg("- %s" % prop, Level.TRACE)
			var val when x.name in copy_props:
				jg_utils.imsg("Allow  ... %s : %s" % [x.name, val], Level.TRACE)
			var val:
				jg_utils.imsg("Else   ... %s : %s" % [x.name, val], Level.TRACE)
	jg_utils.header("----", Level.TRACE)
	exit_copy()
	jg_utils.debug = prev_debug

#  predicates --------------------------------------------------

func get_script_props(obj) -> Array:
	if obj.get("script") == null:
		return []

	return Array(obj
		.get("script").get_script_property_list()
		.map(func(val): return val.name)
		)

func get_copy_props(obj) -> Array:
	""" Get props that need to be copied

	Includes any props that point to:
	- resources,
	- scripts,
	- exported script props
	"""
	if obj == null: return []

	var properties  = obj.get_property_list()
	var sprops		= get_script_props(obj)
	var allowed		= properties.filter(func(elem): return allow_prop(elem, sprops))
	return allowed

func allow_prop(prop, script_props:=[]): # maybe[dict] -> bool
	""" Test whether a property of an object is introspected for copying resources """
	match prop:
		null:
			return false
		{"name": "script", ..}:
			return false
		{"name": var name, ..} when prop.name in script_props:
			return false
		{"name": var name, ..} when name.get_extension() == "gd":
			return false
		{"name": var name, ..} when name in exclusions:
			return false
		{"name": var name, "class_name": var cls, ..} when cls == &"":
			return false
		_:
			return true

func allow_resource(obj): # maybe[obj] -> bool
	"""
	Test whether a resource is allowed to be copied
	"""
	# if obj != null:
	# 	print("obj: %s : in whitelist: %s : %s" % [obj, obj.resource_path in resource_whitelist, resource_whitelist])
	match obj:
		null:
			return false
		_ when not is_instance_valid(obj):
			return false
		_ when not obj.has_method("is_class"):
			return false
		_ when not obj.is_class("Resource"):
			return false
		_ when obj.get_path() == "":   return false
		_ when obj.get_path() == null: return false
		_ when obj.get_path().contains(skip_dirs):
			jg_utils.imsg("Skipping addon: %s" % obj.get_path(), Level.USER)
			return false
		_ when not resource_whitelist.is_empty() and obj.get_path() not in resource_whitelist:
			jg_utils.imsg("Skipping Unselected: %s" % obj.get_path().get_file(), Level.USER)
			return false
		_:
			return true

func allow_subscene(path) -> bool:
	if resource_whitelist.is_empty() or path in resource_whitelist:
		return true

	jg_utils.imsg("Skipping Unselected: %s" % path.get_file(), Level.USER)
	return false

#  enter/exit --------------------------------------------------

func enter_copy(obj) -> bool:
	if obj in handled:
		return false

	jg_utils.msg("->")
	handled.append(obj)
	jg_utils.indent()
	return true

func exit_copy():
	jg_utils.msg("<-")
	jg_utils.deindent()

#  core saving fn --------------------------------------------------

func save_resource(res, new_path): # resource, str -> resource
	if FileAccess.file_exists(new_path) and not self.allow_overwrite:
		jg_utils.imsg("Resource already exists: %s" % new_path, Level.USER)
		return res

	assert(res.resource_path, "Resource has no path: %s" % res)
	const msg_level		= Level.TRACE
	var res_path	= res.resource_path
	var init_uid	= ResourceUID.path_to_uid(res_path)
	res				= res.duplicate()
	var target_ext  = new_path.get_extension()
	var exts		= Array(ResourceSaver.get_recognized_extensions(res))
	jg_utils.imsg("Available Extensions for saving: %s" % ", ".join(exts), Level.TRACE)

	match target_ext in exts:
		_ when target_ext == "gd":
			jg_utils.imsg("saving gdscript: %s (%s) -> %s " % [res_path, ResourceUID.path_to_uid(res_path), new_path], msg_level)
			assert(ResourceSaver.save(res, new_path, self.save_flags) == OK, "Saving Script Failed: %s" % res)

		true: # save using the resource saver
			jg_utils.imsg("saving with resource saver: %s (%s) -> %s " % [res_path, ResourceUID.path_to_uid(res_path), new_path], msg_level)
			assert(ResourceSaver.save(res, new_path, self.save_flags) == OK, "Saving Resource Failed: %s" % res)
			assert(FileAccess.file_exists(new_path), "New File doesn't exist: %s" % new_path)

		false: # save using file access
			jg_utils.imsg("saving using file access: %s (%s) -> %s " % [res_path, ResourceUID.path_to_uid(res_path), new_path], msg_level)
			var data = FileAccess.get_file_as_bytes(res_path)
			assert(len(data) > 0, "No data was read: %s" % res_path)
			var file = FileAccess.open(new_path, FileAccess.WRITE)
			assert(file != null, "Opening Target File to write failed: %s" % new_path)
			assert(file.store_buffer(data), "Writing to File Failed: %s" % new_path)
			file.close()


	assert(FileAccess.file_exists(new_path), "New File doesn't exist: %s" % new_path)
	ResourceSaver.set_uid(new_path, ResourceUID.create_id_for_path(new_path))
	# EditorInterface.get_resource_filesystem().reimport_files([ new_path ])
	# var reloaded = load(new_path)
	res.take_over_path(new_path)
	res.resource_path = jg_utils.as_target(new_path, export_relative)

	var new_uid = ResourceUID.path_to_uid(new_path)
	assert(init_uid != new_uid, "UID didn't change: %s" % new_path)
	# assert(new_uid != new_path, "UID wasn't: %s" % new_path)

	return res

#  main logic --------------------------------------------------

func walk_resources(args) -> Dictionary:
	""" List all transitive dependencies of [args]

	Includes the transitive base classes of scripts,
	and resources of themes.

	"""
	assert(not registered_groups.is_empty(), "No Registered groups")
	# Initialize the result dict with categories:
	var result		= registered_groups.values().reduce(func(accum, elem): return accum.merged({elem : []}), {"Misc" : []})
	jg_utils.msg("Registered groups: %s" % [registered_groups.values()])
	var remaining	= Array(args)
	var found		= JGSet.new()

	jg_utils.msg("Walking: %s" % [args], Level.USER)
	while not remaining.is_empty():
		var curr = remaining.pop_front()
		if found.has(curr):
			continue
		found.add(curr)
		match curr.get_extension():
			var ext when ext in registered_groups:
				result[registered_groups[ext]].append(curr)
			_:
				result["Misc"].append(curr)

		if curr.get_extension() == "gd":
			match ResourceLoader.load(curr).get_base_script():
				null: pass
				var obj when not is_instance_valid(obj):
					pass
				var script when script.resource_path:
					print("base script: %s" % script.resource_path)
					remaining.push_back(script.resource_path)

		var deps = ResourceLoader.get_dependencies(curr)
		if len(deps) == 0: continue
		for x in deps:
			if "::" in x:
				var fpath = x.split("::")[2]
				remaining.push_back(fpath)

	for cat in result:
		result[cat].sort()

	return result

func copy_resource(arg): # str -> maybe[resource]
	assert(typeof(arg) == TYPE_STRING, "Resource is not a string: %s" % arg)
	if not enter_copy(arg):
		return arg

	var result = null
	# save based on available extensions
	match arg.get_extension():
		"tscn","scn":
			result = copy_scene(arg)
		_ when self.save_flags == ResourceSaver.FLAG_BUNDLE_RESOURCES:
			print("Bundling: %s" % arg)
			exit_copy()
			return arg
		"tres", "res":
			result = copy_godot_format(arg)
		"gd":
			result = copy_gdscript(arg)
		_:
			result = copy_file(arg)

	exit_copy()
	return result

func copy_scene(arg): # str -> resource
	jg_utils.header("Copying Scene: %s : %s" % [arg.to_upper(), type_string(typeof(arg))], Level.USER)
	var target		= jg_utils.as_target(arg)
	var res			= ResourceLoader.load(arg, "", cache_mode)
	var inst		= res.instantiate()
	inst.name		= mod_name % inst.name

	var marker		= Node.new()
	marker.name		= "JGCollectMarker"

	handle_props(inst)
	handle_children(inst)

	jg_utils.header("Added Marker to: %s" % inst, Level.TRACE)
	inst.add_child(marker)
	marker.owner = inst

	var repacked = jg_utils.pack_scene(inst)
	repacked.resource_path  = target
	var result				= save_resource(repacked, target)
	handled					= []
	return result

func copy_godot_format(arg): # str -> resource
	jg_utils.header("Copying godot resource: %s" % arg.to_upper(), Level.USER)
	var target		= jg_utils.as_target(arg)
	var res			= ResourceLoader.load(arg, "", cache_mode)
	jg_utils.imsg("- Loaded GD Format: %s" % res, Level.TRACE)
	handle_props(res)
	return save_resource(res, target)

func copy_gdscript(arg): # str -> resource:
	jg_utils.header("Copying gdscript: %s" % arg.to_upper(), Level.USER)
	var target			= jg_utils.as_target(arg)
	var res				= ResourceLoader.load(arg, "", cache_mode)
	match res.get_base_script():
		null: pass
		var superscript when is_instance_valid(superscript) and allow_resource(superscript):
			jg_utils.imsg("Script has a relevant super: %s : %s" % [res, superscript])
			copy_gdscript(superscript.resource_path)

	return save_resource(res, target)

func copy_file(arg): # str -> resource
	jg_utils.header("Copying file: %s" % arg.to_upper(), Level.USER)
	var target		= jg_utils.as_target(arg)
	var res			= ResourceLoader.load(arg, "", cache_mode)
	jg_utils.imsg("Loaded File: %s" % res, Level.TRACE)
	return save_resource(res, target)

func handle_children(arg): # node -> none
	var children = arg.find_children("*", "", false)
	for child in children:
		jg_utils.header("Child: %s" % child.name.to_upper(), Level.TRACE)
		handle_props(child)
		match child.scene_file_path:
			null, "":
				enter_copy(child)
				handle_children(child)
				exit_copy()
			var path when not allow_subscene(path):
				continue
			var path:
				copy_resource(path)
				var target	= jg_utils.as_target(path)
				child.scene_file_path = target

func handle_props(obj): # obj -> none
	var val		= null
	var sprops = get_script_props(obj)
	var sprop_vals = sprops.map(func(elem): return [elem, obj.get(elem)])

	# Copy properties with resources, and properties that are exported from scripts
	for prop in get_copy_props(obj):
		assert(prop.name != "script")
		assert(prop.name not in sprops)
		val = obj.get(prop.name)
		match val:
			null: pass
			_ when allow_resource(val):
				jg_utils.imsg("prop: %s" % prop.name.to_upper(), Level.TRACE)
				match copy_resource(val.resource_path):
					null: pass
					var result:
						jg_utils.imsg("Setting Prop: %s -> %s -> %s" % [obj, prop.name.to_upper(), result], Level.DETAIL)
						obj.set(prop.name, result)

	# Then handle scripts
	match obj.get_script():
		null:
			return
		var script when not is_instance_valid(script):
			return
		var script when not allow_resource(script):
			return

	match copy_resource(obj.get_script().resource_path):
		null:
			pass
		var script:
			jg_utils.imsg("Setting Script: %s -> %s -> %s" % [obj, "script", script], Level.DETAIL)
			obj.set_script(script)

	# Then reapply script props:
	for pair in sprop_vals:
		match pair:
			[var prop, var pval]:

				jg_utils.imsg("Setting Script Prop: %s -> %s -> %s" % [obj, prop.to_upper(), pval], Level.DETAIL)
				obj.set(prop, pval)
