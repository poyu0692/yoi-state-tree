@tool
class_name YoiPropertySensor
extends YoiSensor
## ノードのプロパティ値を毎tickBlackboardに書き込むSensor。

const WARN_NO_BLACKBOARD_KEY := "blackboard_key is not set."
const WARN_NO_NODE_PATH := "node_path is not set."
const WARN_NO_PROPERTY_PATH := "property_path is not set."
const WARN_NODE_NOT_RESOLVED := "node_path \"%s\" could not be resolved."
const WARN_PROPERTY_NOT_FOUND := "property_path \"%s\" not found on node \"%s\"."

@export var blackboard_key: StringName = &""
@export var node_path: NodePath
@export var property_path: String

var _resolved_property: NodePath


func _get_warnings(owner: Node) -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append(WARN_NO_BLACKBOARD_KEY)
	if node_path.is_empty():
		warnings.append(WARN_NO_NODE_PATH)
	if property_path.is_empty():
		warnings.append(WARN_NO_PROPERTY_PATH)
	if not node_path.is_empty() and not property_path.is_empty():
		var node := owner.get_node_or_null(node_path)
		if node == null:
			warnings.append(WARN_NODE_NOT_RESOLVED % node_path)
		else:
			var root_prop := property_path.get_slice(":", 0)
			var found := false
			for p in node.get_property_list():
				if p["name"] == root_prop:
					found = true
					break
			if not found:
				warnings.append(WARN_PROPERTY_NOT_FOUND % [property_path, node_path])
	return warnings


func _tick(ctx: YoiCtx) -> void:
	if _resolved_property.is_empty():
		_resolved_property = NodePath(property_path)
	var node := ctx.current_state.get_node_or_null(node_path)
	if node == null:
		return
	ctx.bb.set_value(blackboard_key, node.get_indexed(_resolved_property))
