@tool
@icon("res://addons/yoi_state_tree/merge.svg")
class_name CompositeTask
extends YoiTask

enum CombineMode {
	ALL,
	ANY,
}

@export var combine_mode: CombineMode = CombineMode.ALL
## true: 結果が確定した時点で残りの子Taskを評価しない（ALLで最初のFAILURE / ANYで最初のSUCCESSで即return）。
## false: 子Taskを最後まで評価してから集約結果を返す（副作用を全て実行したい場合向け）。
@export var short_circuit: bool = true
@export var tasks: Array[YoiTask] = []


func _inject_editor_refs(owner: Node, bb: YoiBlackboard) -> void:
	super (owner, bb)
	for task in tasks:
		if task != null:
			task._inject_editor_refs(owner, bb)


func _get_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if tasks.is_empty():
		warnings.append("tasks is empty.")
	for i in tasks.size():
		if tasks[i] == null:
			warnings.append("[Tasks][%d] is null." % i)
		elif tasks[i] == self:
			warnings.append("[Tasks][%d] cannot reference itself." % i)
	return warnings


func _enter(ctx: YoiCtx) -> int:
	return _aggregate_enter(ctx)


func _tick(delta: float, ctx: YoiCtx) -> int:
	return _aggregate_tick(delta, ctx)


func _exit(ctx: YoiCtx) -> void:
	for task in tasks:
		if task != null and task != self:
			task._exit(ctx)


func _aggregate_enter(ctx: YoiCtx) -> int:
	if tasks.is_empty():
		return SUCCESS if combine_mode == CombineMode.ALL else FAILURE
	match combine_mode:
		CombineMode.ALL:
			var all_succeeded := true
			var has_failure := false
			for task in tasks:
				if task == null or task == self:
					continue
				var status: int = task._enter(ctx)
				if status == FAILURE:
					has_failure = true
					if short_circuit:
						return FAILURE
				if status == RUNNING:
					all_succeeded = false
			if has_failure:
				return FAILURE
			return SUCCESS if all_succeeded else RUNNING
		CombineMode.ANY:
			var any_running := false
			var any_success := false
			for task in tasks:
				if task == null or task == self:
					continue
				var status: int = task._enter(ctx)
				if status == SUCCESS:
					any_success = true
					if short_circuit:
						return SUCCESS
				if status == RUNNING:
					any_running = true
			if any_success:
				return SUCCESS
			return RUNNING if any_running else FAILURE
	return FAILURE


func _aggregate_tick(delta: float, ctx: YoiCtx) -> int:
	if tasks.is_empty():
		return SUCCESS if combine_mode == CombineMode.ALL else FAILURE
	match combine_mode:
		CombineMode.ALL:
			var all_succeeded := true
			var has_failure := false
			for task in tasks:
				if task == null or task == self:
					continue
				var status: int = task._tick(delta, ctx)
				if status == FAILURE:
					has_failure = true
					if short_circuit:
						return FAILURE
				if status == RUNNING:
					all_succeeded = false
			if has_failure:
				return FAILURE
			return SUCCESS if all_succeeded else RUNNING
		CombineMode.ANY:
			var any_running := false
			var any_success := false
			for task in tasks:
				if task == null or task == self:
					continue
				var status: int = task._tick(delta, ctx)
				if status == SUCCESS:
					any_success = true
					if short_circuit:
						return SUCCESS
				if status == RUNNING:
					any_running = true
			if any_success:
				return SUCCESS
			return RUNNING if any_running else FAILURE
	return FAILURE
