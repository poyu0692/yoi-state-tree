@icon("res://addons/yoi_state_tree/presentation.svg")
class_name YoiBlackboard
extends Resource

@export var data: Dictionary[StringName, Variant] = {}


func set_value(key: StringName, value: Variant) -> void:
	data[key] = value


func get_value(key: StringName, default: Variant = null) -> Variant:
	return data.get(key, default)


func has_value(key: StringName) -> bool:
	return data.has(key)
