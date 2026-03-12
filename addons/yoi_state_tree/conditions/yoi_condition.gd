@tool
@abstract
class_name YoiCondition
extends Resource

@export var invert: bool = false


@abstract
func _evaluate(blackboard: YoiBlackboard) -> bool
