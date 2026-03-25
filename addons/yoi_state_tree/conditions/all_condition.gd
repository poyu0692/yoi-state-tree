@tool
class_name AllCondition
extends YoiCondition
## 全ての子Conditionが true のとき true（AND結合）。


@export var conditions: Array[YoiCondition] = []


func _inject_editor_blackboard(bb: YoiBlackboard) -> void:
	super (bb)
	for condition in conditions:
		if condition != null:
			condition._inject_editor_blackboard(bb)


func _get_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if conditions.is_empty():
		warnings.append("conditions is empty.")
	for i in conditions.size():
		if conditions[i] == null:
			warnings.append("[Conditions][%d] is null." % i)
			continue
		for w in conditions[i]._get_warnings():
			warnings.append("[Conditions][%d] %s" % [i, w])
	return warnings


func _evaluate(blackboard: YoiBlackboard) -> bool:
	for condition in conditions:
		if condition == null:
			continue
		var result := condition._evaluate(blackboard)
		if condition.invert:
			result = not result
		if not result:
			return false
	return true
