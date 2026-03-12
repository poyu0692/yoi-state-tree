@icon("res://addons/yoi_state_tree/log-out.svg")
class_name YoiTransition
extends Node

enum Trigger {
	ON_TICK, ## 毎tick、conditionsを評価して発火
	ON_SUCCEEDED, ## ステートのタスクがSUCCEEDEDになったとき
	ON_FAILED, ## ステートのタスクがFAILEDになったとき
	ON_COMPLETED, ## SUCCEEDED または FAILED どちらでも
	ON_EVENT, ## send_event() で発火
}

@export var trigger: Trigger = Trigger.ON_TICK
@export var conditions: Array[YoiCondition] = []
@export var event: StringName = &""
@export var target_state: YoiState
