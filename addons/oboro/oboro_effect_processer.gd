class_name OboroEffectProcesser
extends RefCounted

var _oboro: WeakRef


## Stores a weakref to the given OboroComponent for ctx generation.
func setup(oboro: OboroComponent) -> void:
	_oboro = weakref(oboro)


## Checks if an ability can be activated by name.
func can_activate(states: OboroStates, ability_name: StringName) -> bool:
	var ctx := _create_ability_ctx(states)
	for ability: OboroAbility in states.abilities:
		if ability.ability_name == ability_name:
			return ability.can_activate(ctx)
	return false


## Activates an ability by name. Returns true if successfully activated.
func activate(states: OboroStates, ability_name: StringName) -> bool:
	var ctx := _create_ability_ctx(states)
	for ability: OboroAbility in states.abilities:
		if ability.ability_name == ability_name:
			if ability.can_activate(ctx):
				ability.invoke(ctx)
				return true
	return false


## Applies an effect to the given states, handling conditions and stacking. Returns true if successfully applied.
func apply(states: OboroStates, effect: OboroEffect, source: OboroStates = null) -> bool:
	for req in effect.required_tags:
		if not states.has_tag(req):
			return false
	for block in effect.blocking_tags:
		if states.has_tag(block):
			return false

	var applied: OboroEffect
	if effect.duration_type == OboroEffect.Duration.INSTANT:
		states.apply_modifiers_instant(effect, source)
		_apply_ability_changes(states, effect)
		applied = effect
	else:
		var inst := _resolve_stacking(states, effect, source)
		if inst == null:
			return false
		applied = inst

	states.effect_applied.emit(applied)
	return true


# --- private ---

## Resolves stacking for the given effect. Returns the instance to add (or null for DENY).
## For AGGREGATE with existing effects, returns the existing instance without adding a new one.
func _resolve_stacking(states: OboroStates, effect: OboroEffect, source: OboroStates = null) -> OboroEffect:
	if effect.stacking == OboroEffect.Stacking.SEPARATE:
		return _create_instance(states, effect, source)

	var existing := _find_existing(states, effect)
	match effect.stacking:
		OboroEffect.Stacking.DENY:
			if existing:
				return null
		OboroEffect.Stacking.OVERRIDE:
			if existing:
				states.remove(existing)
		OboroEffect.Stacking.AGGREGATE:
			if existing:
				if existing.stacks < effect.max_stacks:
					existing.stacks += 1
				_apply_stack_duration(existing, effect)
				return existing

	return _create_instance(states, effect, source)


## Creates a new instance of the effect and adds it to the state.
func _create_instance(states: OboroStates, effect: OboroEffect, source: OboroStates = null) -> OboroEffect:
	var inst := effect.duplicate() as OboroEffect
	inst._source = effect
	inst.source_states = source
	if effect.duration_type == OboroEffect.Duration.DURATIONAL:
		inst.remaining = effect.duration
	states.effects.append(inst)
	states.apply_effect_tags(inst)
	states.recalculate_affected(inst)
	if effect.execute_on_apply and effect.period > 0.0:
		states.apply_modifiers_periodic(inst, source)
	_apply_ability_changes(states, effect)
	return inst


## Finds an existing instance of the given effect in the states.
func _find_existing(states: OboroStates, effect: OboroEffect) -> OboroEffect:
	for inst: OboroEffect in states.effects:
		if inst._source == effect:
			return inst
	return null


## Applies ability grants and revokes from the effect.
func _apply_ability_changes(states: OboroStates, effect: OboroEffect) -> void:
	var ctx := _create_ability_ctx(states)
	for ability: OboroAbility in effect.grants_abilities:
		states.grant_ability(ability, ctx)
	for ability_name: StringName in effect.revokes_abilities_by_name:
		states.revoke_ability(ability_name, ctx)
	if not effect.revokes_abilities_by_tag.is_empty():
		var to_revoke: Array[OboroAbility] = []
		for a: OboroAbility in states.abilities:
			for t in a.active_tags:
				var matched := false
				for q in effect.revokes_abilities_by_tag:
					if t == q or t.begins_with(q + "."):
						matched = true
						break
				if matched:
					to_revoke.append(a)
					break
		for a in to_revoke:
			states.revoke_ability(a.ability_name, ctx)


func _create_ability_ctx(states: OboroStates) -> OboroAbilityCtx:
	var ctx := OboroAbilityCtx.new()
	ctx.state = states
	ctx.effects = self
	var oboro := _oboro.get_ref() as OboroComponent if _oboro else null
	if oboro:
		ctx.oboro = oboro
		ctx.owner = oboro.owner
		ctx.tree = oboro.get_tree()
	return ctx


## Applies the stack duration policy to an existing effect instance.
func _apply_stack_duration(inst: OboroEffect, effect: OboroEffect) -> void:
	if effect.duration_type != OboroEffect.Duration.DURATIONAL:
		return
	match effect.stack_duration:
		OboroEffect.StackDuration.RESET:
			inst.remaining = effect.duration
		OboroEffect.StackDuration.ADD:
			inst.remaining += effect.duration
		OboroEffect.StackDuration.MAX:
			inst.remaining = maxf(inst.remaining, effect.duration)
