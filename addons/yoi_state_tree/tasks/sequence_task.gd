@tool
@icon("res://addons/yoi_state_tree/merge.svg")
class_name SequenceTask
extends CompositeTask
## 全ての子Taskが SUCCESS を返したとき SUCCESS。
## 最初に FAILURE を返した時点で即 FAILURE（short-circuit）。


func _enter(ctx: YoiCtx) -> int:
	return _aggregate_enter(true, true, ctx)


func _tick(delta: float, ctx: YoiCtx) -> int:
	return _aggregate_tick(true, true, delta, ctx)
