@tool
@icon("res://addons/yoi_state_tree/merge.svg")
class_name ParallelSequenceTask
extends CompositeTask
## 全ての子Taskを最後まで評価し、全て SUCCESS なら SUCCESS。
## いずれかが FAILURE なら FAILURE（short-circuit なし）。


func _enter(ctx: YoiCtx) -> int:
	return _aggregate_enter(true, false, ctx)


func _tick(delta: float, ctx: YoiCtx) -> int:
	return _aggregate_tick(true, false, delta, ctx)
