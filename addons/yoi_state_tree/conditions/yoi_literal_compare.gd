@tool
class_name YoiLiteralCompare
extends YoiCondition

enum Operator { EQUAL, NOT_EQUAL, LESS, LESS_EQUAL, GREATER, GREATER_EQUAL }

@export var key: StringName
@export var operator: Operator = Operator.EQUAL
@export var value: Variant


func _evaluate(blackboard: YoiBlackboard) -> bool:
	var bb_val = blackboard.get_value(key)
	match operator:
		Operator.EQUAL:
			return bb_val == value
		Operator.NOT_EQUAL:
			return bb_val != value
		Operator.LESS:
			return bb_val < value
		Operator.LESS_EQUAL:
			return bb_val <= value
		Operator.GREATER:
			return bb_val > value
		Operator.GREATER_EQUAL:
			return bb_val >= value
	return false
