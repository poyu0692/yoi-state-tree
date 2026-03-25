@tool
@icon("res://addons/yoi_state_tree/merge.svg")
class_name SelectorTask
extends CompositeTask
## いずれかの子Taskが SUCCESS を返したとき SUCCESS。
## 最初に SUCCESS を返した時点で即 SUCCESS（short-circuit）。


func _enter(ctx: YoiCtx) -> int:
	return _aggregate_enter(false, true, ctx)


func _tick(delta: float, ctx: YoiCtx) -> int:
	return _aggregate_tick(false, true, delta, ctx)
