@tool
@icon("res://addons/yoi_state_tree/log-out.svg")
class_name YoiTransition
extends Resource

enum Trigger {
	ON_TICK, ## triggerなし。毎tickconditionsを評価して発火
	ON_EVENT, ## send_event() で発火
	ON_SUCCEEDED, ## ステートのタスクがSUCCEEDEDになったとき
	ON_FAILED, ## ステートのタスクがFAILEDになったとき
	ON_COMPLETED, ## SUCCEEDED または FAILED どちらでも
	ON_ENTER_SUCCEEDED, ## ステートに入ったとき全タスクの_enterがSUCCESSを返したとき
	ON_ENTER_FAILED, ## ステートに入ったとき任意タスクの_enterがFAILUREを返したとき
}

var trigger: Trigger = Trigger.ON_EVENT:
	set(v):
		trigger = v
		notify_property_list_changed()
var event: StringName = &""
var conditions: Array[YoiCondition] = []
var target_state_path: NodePath


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = [
		{
			"name": "trigger",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "OnTick,OnEvent,OnSucceeded,OnFailed,OnCompleted,OnEnterSucceeded,OnEnterFailed",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]
	if trigger == Trigger.ON_EVENT:
		props.append(
			{
				"name": "event",
				"type": TYPE_STRING_NAME,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT,
			},
		)
	props.append_array(
		[
			{
				"name": "conditions",
				"type": TYPE_ARRAY,
				"hint": PROPERTY_HINT_ARRAY_TYPE,
				"hint_string": "YoiCondition",
				"usage": PROPERTY_USAGE_DEFAULT,
			},
			{
				"name": "target_state_path",
				"type": TYPE_NODE_PATH,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT,
			},
		],
	)
	return props


func _get(property: StringName) -> Variant:
	match property:
		&"trigger":
			return trigger
		&"event":
			return event
		&"conditions":
			return conditions
		&"target_state_path":
			return target_state_path
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"trigger":
			trigger = value
			return true
		&"event":
			event = value
			return true
		&"conditions":
			conditions = value
			return true
		&"target_state_path":
			target_state_path = value
			return true
	return false


func _get_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target_state_path.is_empty():
		warnings.append("target_state_path is empty.")
	if trigger == Trigger.ON_EVENT and event == &"":
		warnings.append("trigger is ON_EVENT but event is empty.")
	for i in conditions.size():
		if conditions[i] == null:
			warnings.append("[Conditions][%d] is null." % i)
			continue
		for w in conditions[i]._get_warnings():
			warnings.append("[Conditions][%d] %s" % [i, w])
	return warnings
