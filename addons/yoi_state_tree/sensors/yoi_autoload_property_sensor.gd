@tool
class_name YoiAutoloadPropertySensor
extends YoiSensor
## Autoloadノードのプロパティ値を毎tickBlackboardに書き込むSensor。

const AUTOLOAD_PROPERTY := "autoload_name"

@export var blackboard_key: StringName = &""
var property_path: String = ""
var autoload_name: String = ""
var _resolved_property: NodePath


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
		{
			"name": "property_path",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]


func _get(property: StringName) -> Variant:
	match property:
		StringName(AUTOLOAD_PROPERTY): return autoload_name
		&"property_path": return property_path
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		StringName(AUTOLOAD_PROPERTY):
			autoload_name = value
			return true
		&"property_path":
			property_path = value
			return true
	return false


func _get_warnings(owner: Node) -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append("blackboard_key is not set.")
	if autoload_name.is_empty():
		warnings.append("autoload_name is not set.")
	if property_path.is_empty():
		warnings.append("property_path is not set.")
	if not autoload_name.is_empty() and not property_path.is_empty():
		var node := owner.get_node_or_null("/root/" + autoload_name)
		if node == null:
			warnings.append("autoload \"%s\" could not be resolved." % autoload_name)
		else:
			var root_prop := property_path.get_slice(":", 0)
			var found := false
			for p in node.get_property_list():
				if p["name"] == root_prop:
					found = true
					break
			if not found:
				warnings.append(
					"property_path \"%s\" not found on autoload \"%s\"."
					% [property_path, autoload_name]
				)
	return warnings


func _tick(ctx: YoiCtx) -> void:
	if _resolved_property.is_empty():
		_resolved_property = NodePath(property_path)
	var node := ctx.current_state.get_node_or_null("/root/" + autoload_name)
	if node == null:
		return
	ctx.bb.set_value(blackboard_key, node.get_indexed(_resolved_property))
