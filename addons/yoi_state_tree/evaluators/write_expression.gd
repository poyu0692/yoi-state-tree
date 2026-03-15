@tool
class_name WriteExpression
extends YoiEvaluator
## BBの値を変数として四則演算などの式を評価し、結果をBlackboardに書き込む。
## variables に列挙したBBキーが、expression_str 内で同名の変数として使える。
## 例) variables: ["base_speed", "multiplier"]  expression_str: "base_speed * multiplier"

var blackboard_key: StringName = &"":
	set(v):
		blackboard_key = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var variables: Array[StringName] = []
var expression_str: String = ""

var _expr: Expression = Expression.new()
var _expr_dirty: bool = true


func _get_property_list() -> Array[Dictionary]:
	var bb_keys: PackedStringArray = []
	if __editor_blackboard != null:
		for k in __editor_blackboard.get_all_keys():
			bb_keys.append(str(k))
	return [
		{
			"name": "blackboard_key",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM if not bb_keys.is_empty() else PROPERTY_HINT_NONE,
			"hint_string": ",".join(bb_keys),
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "variables",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "%d/%d:%s" % [
				TYPE_STRING_NAME,
				PROPERTY_HINT_ENUM if not bb_keys.is_empty() else PROPERTY_HINT_NONE,
				",".join(bb_keys),
			],
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "expression_str",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]


func _get(property: StringName) -> Variant:
	match property:
		&"blackboard_key": return blackboard_key
		&"variables": return variables
		&"expression_str": return expression_str
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"blackboard_key":
			blackboard_key = value
			return true
		&"variables":
			variables = value
			_expr_dirty = true
			return true
		&"expression_str":
			expression_str = value
			_expr_dirty = true
			return true
	return false


func _get_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append("blackboard_key is not set.")
	if expression_str.is_empty():
		warnings.append("expression_str is not set.")
		return warnings
	# パースチェック
	var names := PackedStringArray(variables.map(func(k): return str(k)))
	var test_expr := Expression.new()
	if test_expr.parse(expression_str, names) != OK:
		warnings.append("expression parse error: %s" % test_expr.get_error_text())
		return warnings
	# BB上に変数が存在するかチェック
	if __editor_blackboard != null:
		for v in variables:
			if not __editor_blackboard.has_var(v):
				warnings.append("variable \"%s\" not found in blackboard." % v)
	return warnings


func _tick(ctx: YoiCtx) -> void:
	if _expr_dirty:
		var names := PackedStringArray(variables.map(func(k): return str(k)))
		if _expr.parse(expression_str, names) != OK:
			return
		_expr_dirty = false
	var values: Array = variables.map(func(k): return ctx.bb.get_var(k))
	var result = _expr.execute(values)
	if _expr.has_execute_failed():
		return
	ctx.bb.set_var(blackboard_key, result)
