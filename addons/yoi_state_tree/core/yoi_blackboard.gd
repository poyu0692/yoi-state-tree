@tool
@icon("res://addons/yoi_state_tree/presentation.svg")
class_name YoiBlackboard
extends Resource

signal value_changed(value_key: StringName, current_value: Variant, old_value: Variant)

@export var _data: Dictionary[StringName, Variant] = { }


func set_var(value_key: StringName, value: Variant) -> void:
	var old_value := _data.get(value_key, null)
	if _data.has(value_key) and old_value == value:
		return
	_data[value_key] = value
	value_changed.emit(value_key, value, old_value)


func get_var(value_key: StringName, default: Variant = null) -> Variant:
	return _data.get(value_key, default)


func has_var(value_key: StringName) -> bool:
	return _data.has(value_key)


func get_all_keys() -> Array[StringName]:
	return Array(_data.keys(), TYPE_STRING_NAME, &"", null)
