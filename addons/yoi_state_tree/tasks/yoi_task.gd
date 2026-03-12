@tool
@abstract class_name YoiTask
extends Resource

const SUCCESS := 0
const FAILURE := 1
const RUNNING := 2


func _init() -> void:
	resource_local_to_scene = true


func _enter(ctx: YoiCtx) -> int:
	return SUCCESS


func _tick(delta: float, ctx: YoiCtx) -> int:
	return SUCCESS


func _exit(ctx: YoiCtx) -> void:
	pass
