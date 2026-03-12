class_name YoiCtx
extends RefCounted

var bb: YoiBlackboard
var state_tree: YoiStateTree
var current_state: YoiState
var actor: Node


func _init(p_tree: YoiStateTree, p_state: YoiState) -> void:
	bb = p_tree.blackboard
	state_tree = p_tree
	current_state = p_state
	actor = p_tree.actor


func notify(event_name: StringName, data: Variant = null) -> void:
	state_tree.notified.emit(event_name, data)
