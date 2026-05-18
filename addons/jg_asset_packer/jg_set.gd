#  set.gd -*- mode: gdscript -*-
@tool
class_name JGSet
extends Object
"""
A Set object. Internally a dictionary.
"""


var _values = {}

static func from(args:Array) -> JGSet:
	var new_set = JGSet.new()
	new_set.update(args)
	return new_set

func update(to_add) -> JGSet:
	match typeof(to_add):
		TYPE_ARRAY:
			to_add.map(func(elem): self.add(elem))
		TYPE_DICTIONARY:
			to_add.keys().map(func(elem): self.add(elem))
		_:
			print("Unknown type to update set with: %s" % to_add)

	return self

func add(value) -> void:
	_values[value] = true

func remove(value) -> void:
	_values.erase(value)

func has(value) -> bool:
	return _values.has(value)

func values() -> Array:
	return _values.keys()

func _to_string() -> String:
	return "{ %s }" % ", ".join(self.values())
