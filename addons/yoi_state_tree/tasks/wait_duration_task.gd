@tool
@icon("res://addons/yoi_state_tree/hourglass.svg")
class_name WaitTask
extends YoiTask

@export_range(0.0, 60.0, 0.1, "or_greater", "exp", "suffix:s") var duration: float = 1.0:
	set(v):
		duration = v
		if Engine.is_editor_hint():
			resource_name = str(duration) + "s"

var _elapsed: float = 0.0


func _enter(ctx: YoiCtx) -> int:
	_elapsed = 0.0
	return SUCCESS


func _tick(delta: float, ctx: YoiCtx) -> int:
	_elapsed += delta
	if _elapsed >= duration:
		return SUCCESS
	return RUNNING
