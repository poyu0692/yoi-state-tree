@tool
@icon("res://addons/yoi_state_tree/orbit (1).svg")
class_name YoiStateTree
extends Node

signal state_entered(state: YoiState)
signal state_exited(state: YoiState)
signal transition_taken(from_state: YoiState, to_state: YoiState)
signal state_leaf_changed(current_state: StringName)
signal notified(event_name: StringName, data: Variant)

enum UpdateMode {PROCESS, PHYSICS, MANUAL}

@export var active: bool = true
@export var autostart: bool = true
@export var actor: Node
@export var blackboard: YoiBlackboard
@export var update_mode: UpdateMode = UpdateMode.PHYSICS
@export_range(0.0, 10.0, 0.01, "or_greater") var tick_interval: float = 0.0

var _active_path: Array[YoiState] = []
var _running: bool = false
var _pending_events: Array[StringName] = []
var _tick_timer: float = 0.0
var _root_state: YoiState
var _state_child_states: Dictionary[YoiState, Array] = {}
var _transition_targets: Dictionary[YoiTransition, YoiState] = {}
var _state_enter_status: Dictionary[YoiState, int] = {} ## state → enter結果(SUCCESS/FAILURE/RUNNING)、最初のtick評価後にconsume


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if autostart:
		start()


func _process(delta: float) -> void:
	if update_mode == UpdateMode.PROCESS:
		_try_tick(delta)


func _physics_process(delta: float) -> void:
	if update_mode == UpdateMode.PHYSICS:
		_try_tick(delta)


func tick(delta: float) -> void:
	if update_mode == UpdateMode.MANUAL:
		_try_tick(delta)


func send_event(event: StringName) -> void:
	_pending_events.append(event)


func start() -> void:
	if _running:
		return
	_rebuild_runtime_cache()
	var root := _root_state
	if root == null:
		push_error("YoiStateTree: no YoiState child found")
		return
	if blackboard == null:
		push_error("YoiStateTree: blackboard is not assigned")
		return
	_running = true
	for state in _build_path_to_leaf(root):
		_enter_state(state)
	var current := get_current_state()
	if current != null:
		state_leaf_changed.emit(_to_state_key(current))


func stop() -> void:
	if not _running:
		return
	for i in range(_active_path.size() - 1, -1, -1):
		_exit_state(_active_path[i])
	_active_path.clear()
	_state_enter_status.clear()
	_running = false


func is_running() -> bool:
	return _running


func get_active_path() -> Array[YoiState]:
	return _active_path.duplicate()


func get_current_state() -> YoiState:
	if _active_path.is_empty():
		return null
	return _active_path.back()


func _try_tick(delta: float) -> void:
	if not active or not _running:
		return
	_tick_timer += delta
	if _tick_timer < tick_interval:
		return
	_tick_timer = 0.0
	_tick(delta)


func _tick(delta: float) -> void:
	# 1. Sensors tick (root → leaf)
	for state in _active_path:
		for evaluator in state.evaluators:
			if evaluator != null:
				evaluator._tick(YoiCtx.new(self , state))

	# 2. Tasks tick (root → leaf) → Status収集
	var state_statuses: Dictionary = {}
	for state in _active_path:
		state_statuses[state] = _tick_state_tasks(state, delta)

	# 3. Transitions check (leaf → root)
	var transition_target: YoiState = null
	for i in range(_active_path.size() - 1, -1, -1):
		var state := _active_path[i]
		var status: int = state_statuses.get(state, YoiTask.RUNNING)
		for transition in state.transitions:
			if _evaluate_transition(state, transition, status):
				transition_target = _transition_targets[transition]
				break
		_state_enter_status.erase(state) # ON_ENTER_*は1tick限り有効
		if transition_target != null:
			break

	# 4. State change (if transition fired)
	if transition_target != null:
		var from_leaf := get_current_state()
		_do_transition(transition_target)
		var to_leaf := get_current_state()
		transition_taken.emit(from_leaf, to_leaf)
		if from_leaf != to_leaf and to_leaf != null:
			state_leaf_changed.emit(_to_state_key(to_leaf))




# 複数タスクのStatus集約: 1つでもFAILED→FAILED、全部SUCCEEDED→SUCCEEDED、それ以外→RUNNING
func _tick_state_tasks(state: YoiState, delta: float) -> int:
	if state.tasks.is_empty():
		return YoiTask.RUNNING
	var ctx := YoiCtx.new(self , state)
	var all_succeeded := true
	for task in state.tasks:
		var s: int = task._tick(delta, ctx)
		if s == YoiTask.FAILURE:
			return YoiTask.FAILURE
		if s == YoiTask.RUNNING:
			all_succeeded = false
	return YoiTask.SUCCESS if all_succeeded else YoiTask.RUNNING


func _evaluate_transition(
		_owner_state: YoiState,
		transition: YoiTransition,
		state_status: int,
) -> bool:
	if not _transition_targets.has(transition):
		return false

	# トリガー種別チェック
	match transition.trigger:
		YoiTransition.Trigger.ON_TICK:
			pass # 毎tick conditionsを評価する
		YoiTransition.Trigger.ON_SUCCEEDED:
			if state_status != YoiTask.SUCCESS:
				return false
		YoiTransition.Trigger.ON_FAILED:
			if state_status != YoiTask.FAILURE:
				return false
		YoiTransition.Trigger.ON_COMPLETED:
			if state_status == YoiTask.RUNNING:
				return false
		YoiTransition.Trigger.ON_EVENT:
			var idx := _pending_events.find(transition.event)
			if transition.event == &"" or idx == -1:
				return false
			_pending_events.remove_at(idx)
		YoiTransition.Trigger.ON_ENTER_SUCCEEDED:
			if _state_enter_status.get(_owner_state, -1) != YoiTask.SUCCESS:
				return false
		YoiTransition.Trigger.ON_ENTER_FAILED:
			if _state_enter_status.get(_owner_state, -1) != YoiTask.FAILURE:
				return false

	# Conditions評価（AND結合）
	for condition in transition.conditions:
		if condition == null:
			continue
		var result: bool = condition._evaluate(blackboard)
		if condition.invert:
			result = not result
		if not result:
			return false
	return true


func _do_transition(target: YoiState) -> void:
	var full_new_path := _build_path_from_root(target)
	# targetからリーフまで降下して追加
	var leaf_descent := _build_path_to_leaf(target)
	for i in range(1, leaf_descent.size()):
		full_new_path.append(leaf_descent[i])

	# 共通祖先インデックスを特定
	var common_len := 0
	for i in range(mini(_active_path.size(), full_new_path.size())):
		if _active_path[i] == full_new_path[i]:
			common_len = i + 1
		else:
			break

	# Exit: 旧パスの差分 (leaf → 共通祖先の次)
	for i in range(_active_path.size() - 1, common_len - 1, -1):
		_exit_state(_active_path[i])
	_active_path.resize(common_len)

	# Enter: 新パスの差分 (共通祖先の次 → 新leaf)
	for j in range(common_len, full_new_path.size()):
		_enter_state(full_new_path[j])


func _enter_state(state: YoiState) -> void:
	var ctx := YoiCtx.new(self , state)
	_state_enter_status[state] = _compute_enter_status(state, ctx)
	_active_path.append(state)
	state_entered.emit(state)


func _compute_enter_status(state: YoiState, ctx: YoiCtx) -> int:
	if state.tasks.is_empty():
		return YoiTask.SUCCESS
	var all_succeeded := true
	for task in state.tasks:
		var s: int = task._enter(ctx)
		if s == YoiTask.FAILURE:
			return YoiTask.FAILURE
		if s == YoiTask.RUNNING:
			all_succeeded = false
	return YoiTask.SUCCESS if all_succeeded else YoiTask.RUNNING


func _exit_state(state: YoiState) -> void:
	var ctx := YoiCtx.new(self , state)
	for task in state.tasks:
		task._exit(ctx)
	state_exited.emit(state)


# Enter Conditionsを満たす候補をselection_modeに従って選択
func _select_child_state(state: YoiState) -> YoiState:
	var candidates: Array[YoiState] = []
	for child in _state_child_states.get(state, []):
		if _check_enter_conditions(child):
			candidates.append(child)
	if candidates.is_empty():
		return null
	match state.selection_mode:
		YoiState.SelectionMode.RANDOM:
			return candidates[randi() % candidates.size()]
		YoiState.SelectionMode.HIGHEST_WEIGHT:
			return _select_highest_weight(candidates)
		YoiState.SelectionMode.WEIGHTED_RANDOM:
			return _select_weighted_random(candidates)
		_:
			return candidates[0]


func _evaluate_weight(state: YoiState) -> float:
	if state.selection_weight == null:
		return 0.0
	return state.selection_weight.evaluate(blackboard)


func _select_highest_weight(candidates: Array[YoiState]) -> YoiState:
	var best: YoiState = candidates[0]
	var best_score := _evaluate_weight(candidates[0])
	for i in range(1, candidates.size()):
		var score := _evaluate_weight(candidates[i])
		if score > best_score:
			best_score = score
			best = candidates[i]
	return best


func _select_weighted_random(candidates: Array[YoiState]) -> YoiState:
	var scores: Array[float] = []
	var total := 0.0
	for state in candidates:
		var s := maxf(_evaluate_weight(state), 0.0)
		scores.append(s)
		total += s
	if total <= 0.0:
		return candidates[randi() % candidates.size()]
	var roll := randf() * total
	var cumulative := 0.0
	for i in candidates.size():
		cumulative += scores[i]
		if roll < cumulative:
			return candidates[i]
	return candidates.back()


func _check_enter_conditions(state: YoiState) -> bool:
	for condition in state.enter_conditions:
		if condition == null:
			continue
		var result: bool = condition._evaluate(blackboard)
		if condition.invert:
			result = not result
		if not result:
			return false
	return true


func _build_path_to_leaf(from: YoiState) -> Array[YoiState]:
	var path: Array[YoiState] = [from]
	var current := from
	while true:
		var next := _select_child_state(current)
		if next == null:
			break
		current = next
		path.append(current)
	return path


func _build_path_from_root(state: YoiState) -> Array[YoiState]:
	var path: Array[YoiState] = []
	var current: Node = state
	while current != null and current != self:
		if current is YoiState:
			path.push_front(current)
		current = current.get_parent()
	return path


func _to_state_key(state: YoiState) -> StringName:
	return StringName(String(state.name).to_snake_case())


func _rebuild_runtime_cache() -> void:
	_root_state = null
	_state_child_states.clear()
	_transition_targets.clear()

	for child in get_children():
		if child is YoiState:
			if _root_state == null:
				_root_state = child

	for child in get_children():
		if child is YoiState:
			_cache_child_states_recursive(child)


func _cache_child_states_recursive(state: YoiState) -> void:
	var child_states: Array[YoiState] = []
	for child in state.get_children():
		if child is YoiState:
			child_states.append(child)
	_state_child_states[state] = child_states

	for transition in state.transitions:
		if not transition.target_state_path.is_empty():
			var target := state.get_node_or_null(transition.target_state_path)
			if target is YoiState:
				_transition_targets[transition] = target
			else:
				push_warning("YoiStateTree: invalid target_state_path '%s' in transition" % transition.target_state_path)

	for child in child_states:
		_cache_child_states_recursive(child)
