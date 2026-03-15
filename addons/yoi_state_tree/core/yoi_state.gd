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
@export var evaluators: Array[YoiEvaluator] = []
@export var enter_conditions: Array[YoiCondition] = []
@export_group("Tasks")
@export var tasks: Array[YoiTask] = []
@export_group("Transitions")
@export var transitions: Array[YoiTransition] = []
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
		_inject_blackboard()
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	for i in evaluators.size():
		if evaluators[i] == null:
			warnings.append("[Evaluators][%d] is null." % i)
			continue
		for w in evaluators[i]._get_warnings():
			warnings.append("[Evaluators][%d] %s" % [i, w])

	for i in enter_conditions.size():
		if enter_conditions[i] == null:
			warnings.append("[EnterConditions][%d] is null." % i)
			continue
		for w in enter_conditions[i]._get_warnings():
			warnings.append("[EnterConditions][%d] %s" % [i, w])

	for i in tasks.size():
		if tasks[i] == null:
			warnings.append("[Tasks][%d] is null." % i)
			continue
		for w in tasks[i]._get_warnings():
			warnings.append("[Tasks][%d] %s" % [i, w])

	for i in transitions.size():
		if transitions[i] == null:
			warnings.append("[Transitions][%d] is null." % i)
			continue
		for w in transitions[i]._get_warnings():
			warnings.append("[Transitions][%d] %s" % [i, w])

	var needs_weight := selection_mode in [SelectionMode.HIGHEST_WEIGHT, SelectionMode.WEIGHTED_RANDOM]
	if needs_weight and selection_weight == null:
		warnings.append("[Selection] selection_mode is %s but selection_weight is not set." % SelectionMode.keys()[selection_mode])

	var child_states := get_child_states()
	if child_states.is_empty() and selection_mode != SelectionMode.ORDER:
		warnings.append("[Selection] selection_mode is %s but there are no child YoiStates." % SelectionMode.keys()[selection_mode])

	return warnings


func _inject_blackboard() -> void:
	var bb := _find_blackboard()
	for e in evaluators:
		if e != null:
			e._inject_editor_refs(self, bb)
	for c in enter_conditions:
		if c != null and c.__editor_blackboard != bb:
			c._inject_editor_blackboard(bb)
			c.notify_property_list_changed()
	for task in tasks:
		if task != null:
			task.__editor_blackboard = bb
	for t in transitions:
		if t == null:
			continue
		for c in t.conditions:
			if c != null and c.__editor_blackboard != bb:
				c._inject_editor_blackboard(bb)
				c.notify_property_list_changed()


func _find_blackboard() -> YoiBlackboard:
	var p := get_parent()
	while p != null:
		if p is YoiStateTree:
			return p.blackboard
		p = p.get_parent()
	return null


func get_child_states() -> Array[YoiState]:
	var child_states: Array[YoiState] = []
	for child in get_children():
		if child is YoiState:
			child_states.append(child)
	return child_states
