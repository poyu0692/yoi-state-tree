@icon("res://addons/oboro/volleyball.svg")
class_name OboroComponent
extends Node

## Resource defining the initial attributes for this component.
@export var attr_set: OboroAttrSet
## Damage calculator for processing damage context.
@export var dmg_calc: OboroDmgCalc

## The current state of this component (attributes, effects, abilities, tags).
var state: OboroStates
var _processer: OboroEffectProcesser


func _ready() -> void:
	state = OboroStates.new()
	_processer = OboroEffectProcesser.new()
	_processer.setup(self)
	if attr_set:
		state.init_attrs(attr_set.defs)


func _process(delta: float) -> void:
	state.tick(delta)


## Gets an attribute by name. Returns null if not found.
func get_attr(attr_name: StringName) -> OboroAttr:
	return state.get_attr(attr_name)


## Applies an effect to this component's state. Returns true if successfully applied.
func apply_effect(effect: OboroEffect, source: OboroStates = null) -> bool:
	return _processer.apply(state, effect, source)


## Sends damage to a target. Called by the damage source. Emits pre_damage_sent before calling target.receive_damage.
func send_damage(ctx: OboroDmgCtx, target_oboro: OboroComponent) -> void:
	ctx.source_oboro = self
	state.pre_damage_sent.emit(ctx)
	target_oboro.receive_damage(ctx)


## Receives damage from a source. Emits pre_damage_received and applies damage effect if dmg_calc is set.
func receive_damage(ctx: OboroDmgCtx) -> void:
	ctx.target_oboro = self
	state.pre_damage_received.emit(ctx)
	if dmg_calc:
		var effect := dmg_calc.calc(ctx)
		_processer.apply(state, effect)
	state.receive_damage(ctx)


## Checks if an ability can be activated by name.
func can_activate(ability_name: StringName) -> bool:
	var ctx := create_ability_ctx()
	for ability: OboroAbility in state.abilities:
		if ability.ability_name == ability_name:
			return ability.can_activate(ctx)
	return false


## Activates an ability by name. Returns true if the ability was successfully activated.
func activate(ability_name: StringName) -> bool:
	var ctx := create_ability_ctx()
	for ability: OboroAbility in state.abilities:
		if ability.ability_name == ability_name:
			if ability.can_activate(ctx):
				ability.invoke(ctx)
				return true
	return false


func create_ability_ctx() -> OboroAbilityCtx:
	var ctx := OboroAbilityCtx.new()
	ctx.owner = owner
	ctx.oboro = self
	ctx.tree = get_tree()
	ctx.state = state
	ctx.effects = _processer
	return ctx
