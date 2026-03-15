@tool
@icon("res://addons/yoi_state_tree/circle-check-big.svg")
class_name CheckValue
extends YoiCondition

enum Operator { GREATER, GREATER_EQUAL, EQUAL, LESS_EQUAL, LESS, NOT_EQUAL }
enum ValueMode { LITERAL, BB_VALUE }

var blackboard_key: StringName:
	set(v):
		blackboard_key = v
		if Engine.is_editor_hint():
			_update_resource_name()
			notify_property_list_changed()
var operator: Operator = Operator.EQUAL:
	set(v):
		operator = v
		if Engine.is_editor_hint():
			_update_resource_name()
var value_mode: ValueMode = ValueMode.LITERAL:
	set(v):
		value_mode = v
		if Engine.is_editor_hint():
			_update_resource_name()
			notify_property_list_changed()
var value_literal: Variant:
	set(v):
		value_literal = v
		if Engine.is_editor_hint():
			_update_resource_name()
var value_key: StringName = &"":
	set(v):
		value_key = v
		if Engine.is_editor_hint():
			_update_resource_name()


func _inject_editor_blackboard(bb: YoiBlackboard) -> void:
	super(bb)
	notify_property_list_changed()


func _get_property_list() -> Array[Dictionary]:
	var keys: PackedStringArray = []
	if __editor_blackboard != null:
		for k in __editor_blackboard.get_all_keys():
			keys.append(str(k))

	var bb_type := TYPE_NIL
	if __editor_blackboard != null and blackboard_key != &"" \
			and __editor_blackboard.has_var(blackboard_key):
		bb_type = typeof(__editor_blackboard.get_var(blackboard_key))

	var props: Array[Dictionary] = [
		{
			"name": "blackboard_key",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM if not keys.is_empty() else PROPERTY_HINT_NONE,
			"hint_string": ",".join(keys),
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "operator",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ">,>=,==,<=,<,!=",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "value_mode",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Literal,BBValue",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]

	if value_mode == ValueMode.LITERAL:
		props.append({
			"name": "value_literal",
			"type": bb_type if bb_type != TYPE_NIL else TYPE_NIL,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_DEFAULT | (0 if bb_type != TYPE_NIL else PROPERTY_USAGE_NIL_IS_VARIANT),
		})
	else:
		var filtered_keys: PackedStringArray = []
		if __editor_blackboard != null:
			for k in __editor_blackboard.get_all_keys():
				if bb_type == TYPE_NIL or typeof(__editor_blackboard.get_var(k)) == bb_type:
					filtered_keys.append(str(k))
		props.append({
			"name": "value_key",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM if not filtered_keys.is_empty() else PROPERTY_HINT_NONE,
			"hint_string": ",".join(filtered_keys),
			"usage": PROPERTY_USAGE_DEFAULT,
		})

	return props


func _get(property: StringName) -> Variant:
	match property:
		&"blackboard_key": return blackboard_key
		&"operator": return operator
		&"value_mode": return value_mode
		&"value_literal": return value_literal
		&"value_key": return value_key
	return null


func _set(property: StringName, val: Variant) -> bool:
	match property:
		&"blackboard_key":
			blackboard_key = val
			return true
		&"operator":
			operator = val
			return true
		&"value_mode":
			value_mode = val
			return true
		&"value_literal":
			value_literal = val
			return true
		&"value_key":
			value_key = val
			return true
	return false


func _update_resource_name() -> void:
	var op_str := [">", ">=", "==", "<=", "<", "!="][operator] as String
	var val_str: String
	if value_mode == ValueMode.LITERAL:
		val_str = str(value_literal)
	else:
		val_str = "bb." + str(value_key)
	resource_name = "%s %s %s" % [blackboard_key, op_str, val_str]


func _get_warnings() -> PackedStringArray:
	var w: PackedStringArray = []
	if blackboard_key == &"":
		w.append("blackboard_key is empty.")
		return w
	if __editor_blackboard != null and not __editor_blackboard.has_var(blackboard_key):
		w.append("blackboard key '%s' does not exist." % blackboard_key)
		return w
	if value_mode == ValueMode.BB_VALUE:
		if value_key == &"":
			w.append("value_key is not set.")
		elif __editor_blackboard != null:
			if not __editor_blackboard.has_var(value_key):
				w.append("value_key '%s' does not exist in blackboard." % value_key)
			else:
				var bb_type := typeof(__editor_blackboard.get_var(blackboard_key)) \
					if __editor_blackboard.has_var(blackboard_key) else TYPE_NIL
				var key_type := typeof(__editor_blackboard.get_var(value_key))
				if bb_type != TYPE_NIL and key_type != bb_type:
					w.append(
						"type mismatch: blackboard[\"%s\"] is %s but value_key \"%s\" is %s." % [
							blackboard_key, type_string(bb_type),
							value_key, type_string(key_type),
						]
					)
	return w


func _evaluate(blackboard: YoiBlackboard) -> bool:
	var bb_val = blackboard.get_var(blackboard_key)
	var cmp_val: Variant = blackboard.get_var(value_key) \
		if value_mode == ValueMode.BB_VALUE else value_literal
	match operator:
		Operator.EQUAL:
			return bb_val == cmp_val
		Operator.NOT_EQUAL:
			return bb_val != cmp_val
		Operator.LESS:
			return bb_val < cmp_val
		Operator.LESS_EQUAL:
			return bb_val <= cmp_val
		Operator.GREATER:
			return bb_val > cmp_val
		Operator.GREATER_EQUAL:
			return bb_val >= cmp_val
	return false
