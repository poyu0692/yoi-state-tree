@tool
class_name YoiNodeSensor
extends YoiSensor
## ノードの参照を毎tickBlackboardに書き込むSensor。

@export var blackboard_key: StringName = &""
@export var node_path: NodePath


func _get_warnings(owner: Node) -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append("blackboard_key is not set.")
	if node_path.is_empty():
		warnings.append("node_path is not set.")
	elif owner.get_node_or_null(node_path) == null:
		warnings.append("node_path \"%s\" could not be resolved." % node_path)
	return warnings


func _tick(ctx: YoiCtx) -> void:
	ctx.bb.set_value(blackboard_key, ctx.current_state.get_node_or_null(node_path))
