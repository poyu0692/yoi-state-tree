@tool
@icon("res://addons/yoi_state_tree/pencil-line.svg")
@abstract
class_name YoiEvaluator
extends Resource


var __editor_blackboard: YoiBlackboard
var __editor_owner: WeakRef


func _inject_editor_refs(owner: Node, bb: YoiBlackboard) -> void:
	__editor_owner = weakref(owner)
	__editor_blackboard = bb


## エディタ警告を返す。YoiState._get_configuration_warnings() から収集される。
func _get_warnings() -> PackedStringArray:
	return PackedStringArray()


@abstract
func _tick(ctx: YoiCtx) -> void
