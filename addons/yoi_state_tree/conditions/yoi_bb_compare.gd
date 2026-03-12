@tool
class_name YoiBBCompare
extends YoiCondition

enum Operator { EQUAL, NOT_EQUAL, LESS, LESS_EQUAL, GREATER, GREATER_EQUAL }

@export var left_key: StringName
@export var operator: Operator = Operator.EQUAL
@export var right_key: StringName


func _evaluate(bb: YoiBlackboard) -> bool:
	var left = bb.get_value(left_key)
	var right = bb.get_value(right_key)
	match operator:
		Operator.EQUAL:
			return left == right
		Operator.NOT_EQUAL:
			return left != right
		Operator.LESS:
			return left < right
		Operator.LESS_EQUAL:
			return left <= right
		Operator.GREATER:
			return left > right
		Operator.GREATER_EQUAL:
			return left >= right
	return false
