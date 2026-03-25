@abstract
class_name CompositeTask
extends YoiTask

@export var tasks: Array[YoiTask] = []


func _inject_editor_refs(owner: Node, bb: YoiBlackboard) -> void:
	super(owner, bb)
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


func _exit(ctx: YoiCtx) -> void:
	for task in tasks:
		if task != null and task != self:
			task._exit(ctx)


func _aggregate_enter(combine_all: bool, short_circuit: bool, ctx: YoiCtx) -> int:
	if tasks.is_empty():
		return SUCCESS if combine_all else FAILURE
	if combine_all:
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
	else:
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


func _aggregate_tick(combine_all: bool, short_circuit: bool, delta: float, ctx: YoiCtx) -> int:
	if tasks.is_empty():
		return SUCCESS if combine_all else FAILURE
	if combine_all:
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
	else:
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
