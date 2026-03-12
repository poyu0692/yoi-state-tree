@tool
class_name YoiAutoloadNodeSensor
extends YoiSensor

## AutoloadノードのReferenceを毎tickBlackboardに書き込むSensor。
const AUTOLOAD_PROPERTY := "autoload_name"

@export var blackboard_key: StringName = &""

var autoload_name: String = ""


static func _get_autoload_names() -> PackedStringArray:
	var names := PackedStringArray()
	for prop in ProjectSettings.get_property_list():
		if prop["name"].begins_with("autoload/"):
			names.append(prop["name"].trim_prefix("autoload/"))
	return names


func _get_property_list() -> Array[Dictionary]:
	var names := _get_autoload_names()
	var hint_string := ",".join(names) if not names.is_empty() else ""
	return [
		{
			"name": AUTOLOAD_PROPERTY,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": hint_string,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]


func _get(property: StringName) -> Variant:
	if property == StringName(AUTOLOAD_PROPERTY):
		return autoload_name
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == StringName(AUTOLOAD_PROPERTY):
		autoload_name = value
		return true
	return false


func _get_warnings(owner: Node) -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append("blackboard_key is not set.")
	if autoload_name.is_empty():
		warnings.append("autoload_name is not set.")
	return warnings


func _tick(ctx: YoiCtx) -> void:
	ctx.bb.set_value(blackboard_key, ctx.current_state.get_node_or_null("/root/" + autoload_name))
