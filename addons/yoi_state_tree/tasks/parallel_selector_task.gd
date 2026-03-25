@tool
@icon("res://addons/yoi_state_tree/merge.svg")
class_name ParallelSelectorTask
extends CompositeTask
## 全ての子Taskを最後まで評価し、いずれかが SUCCESS なら SUCCESS。
## 全て FAILURE なら FAILURE（short-circuit なし）。


func _enter(ctx: YoiCtx) -> int:
	return _aggregate_enter(false, false, ctx)


func _tick(delta: float, ctx: YoiCtx) -> int:
	return _aggregate_tick(false, false, delta, ctx)
