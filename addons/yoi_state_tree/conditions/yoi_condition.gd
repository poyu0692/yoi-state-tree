@tool
@icon("res://addons/yoi_state_tree/circle-question-mark.svg")
@abstract
class_name YoiCondition
extends Resource

@export_group("Invert")
@export var invert: bool = false

var __editor_blackboard: YoiBlackboard


func _inject_editor_blackboard(bb: YoiBlackboard) -> void:
	__editor_blackboard = bb


func _get_warnings() -> PackedStringArray:
	return PackedStringArray()


@abstract
func _evaluate(blackboard: YoiBlackboard) -> bool
