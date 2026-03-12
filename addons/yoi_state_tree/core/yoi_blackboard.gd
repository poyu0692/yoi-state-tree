@icon("res://addons/yoi_state_tree/presentation.svg")
class_name YoiBlackboard
extends Node

@export var blackboad_schema: Dictionary[StringName, Variant] = { }

var _data: Dictionary[StringName, Variant] = { }


func _ready() -> void:
	_data.merge(blackboad_schema)


func set_value(key: StringName, value: Variant) -> void:
	_data[key] = value


func get_value(key: StringName, default: Variant = null) -> Variant:
	return _data.get(key, default)


func has_value(key: StringName) -> bool:
	return _data.has(key)
