@tool
@icon("res://addons/yoi_state_tree/circle-slash (1).svg")
class_name YoiState
extends Node

enum SelectionMode {
	ORDER, ## enter_conditionsを満たす最初の子を選ぶ
	RANDOM, ## 均等ランダム
	HIGHEST_WEIGHT, ## selection_weightが最大の子を選ぶ
	WEIGHTED_RANDOM, ## selection_weightを重みにしたランダム選択
}

const _WARNING_INTERVAL: float = 1.5

@export_group("Conditions")
@export var sensors: Array[YoiSensor] = []
@export var enter_conditions: Array[YoiCondition] = []
@export_group("Tasks")
@export var tasks: Array[YoiTask] = []
@export_group("Selection")
@export var selection_mode: SelectionMode = SelectionMode.ORDER
@export var selection_weight: YoiSelectionWeight

var _warning_timer: float = 0.0


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	_warning_timer += delta
	if _warning_timer >= _WARNING_INTERVAL:
		_warning_timer = 0.0
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	for i in sensors.size():
		for w in sensors[i]._get_warnings(self):
			warnings.append("[Sensors][%d] %s" % [i, w])
	return warnings


func get_child_states() -> Array[YoiState]:
	var child_states: Array[YoiState] = []
	for child in get_children():
		if child is YoiState:
			child_states.append(child)
	return child_states


func get_transitions() -> Array[YoiTransition]:
	var transitions: Array[YoiTransition] = []
	for child in get_children():
		if child is YoiTransition:
			transitions.append(child)
	return transitions
