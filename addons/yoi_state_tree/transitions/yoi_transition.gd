@icon("res://addons/yoi_state_tree/log-out.svg")
class_name YoiTransition
extends Node

enum Trigger {
	ON_TICK, ## 毎tick、conditionsを評価して発火
	ON_SUCCEEDED, ## ステートのタスクがSUCCEEDEDになったとき
	ON_FAILED, ## ステートのタスクがFAILEDになったとき
	ON_COMPLETED, ## SUCCEEDED または FAILED どちらでも
	ON_EVENT, ## send_event() で発火
	ON_ENTER_SUCCEEDED, ## ステートに入ったとき全タスクの_enterがSUCCESSを返したとき
	ON_ENTER_FAILED, ## ステートに入ったとき任意タスクの_enterがFAILUREを返したとき
}

@export var trigger: Trigger = Trigger.ON_TICK
@export var conditions: Array[YoiCondition] = []
@export var event: StringName = &""
@export var target_state: YoiState
