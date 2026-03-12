@tool
class_name YoiWaitTask
extends YoiTask

@export var duration: float = 1.0

var _elapsed: float = 0.0


func _enter(ctx: YoiCtx) -> int:
	_elapsed = 0.0
	return SUCCESS


func _tick(delta: float, ctx: YoiCtx) -> int:
	_elapsed += delta
	if _elapsed >= duration:
		return SUCCESS
	return RUNNING
