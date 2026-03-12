class_name OboroStates
extends RefCounted

## Emitted when a tag is added.
signal tag_added(tag: String)
## Emitted when a tag is removed.
signal tag_removed(tag: String)
## Emitted when an effect is applied.
signal effect_applied(effect: OboroEffect)
## Emitted when an effect is removed.
signal effect_removed(effect: OboroEffect)
## Emitted before damage is sent to a target.
signal pre_damage_sent(ctx: OboroDmgCtx)
## Emitted before damage is received.
signal pre_damage_received(ctx: OboroDmgCtx)
## Emitted after damage is received.
signal damage_received(ctx: OboroDmgCtx)

## Current tags applied to this state.
var tags: Array[String] = []
## Current attributes indexed by name.
var attrs: Dictionary[StringName, OboroAttr] = { }
## Attribute definitions indexed by name.
var attr_defs: Dictionary[StringName, OboroAttrDef] = { }
## Currently active effects.
var effects: Array[OboroEffect] = []
## Currently granted abilities.
var abilities: Array[OboroAbility] = []
var _evaluator: OboroAttrEvaluator


## Initializes attributes from the given definitions and evaluates derived formulas.
func init_attrs(defs: Array[OboroAttrDef]) -> void:
	_evaluator = OboroAttrEvaluator.new()
	_evaluator.setup(defs)
	for def in defs:
		attrs[def.attr_name] = OboroAttr.new(def.base_value)
		attr_defs[def.attr_name] = def
	## derived式の初期評価（依存順）
	for attr_name in _evaluator.eval_order:
		recalc_attr(attr_name)


## Checks if a tag exists (full match or prefix match). Example: has_tag("status.debuff") matches "status.debuff.burning".
func has_tag(query: String) -> bool:
	var prefix := query + "."
	for tag in tags:
		if tag == query or tag.begins_with(prefix):
			return true
	return false


## Gets an attribute by name.
func get_attr(attr_name: StringName) -> OboroAttr:
	return attrs.get(attr_name)


## Grants an ability to this state, adding its tags.
func grant_ability(ability: OboroAbility, ctx: OboroAbilityCtx = null) -> void:
	if not ability in abilities:
		abilities.append(ability)
		for tag in ability.active_tags:
			add_tag(tag)
		ability.grant(ctx)


## Revokes an ability by name, removing its tags.
func revoke_ability(ability_name: StringName, ctx: OboroAbilityCtx = null) -> void:
	var new_list: Array[OboroAbility] = []
	for a: OboroAbility in abilities:
		if a.ability_name == ability_name:
			for tag in a.active_tags:
				remove_tag(tag)
			a.revoke(ctx)
		else:
			new_list.append(a)
	abilities = new_list


## Adds a tag to the state if not already present.
func add_tag(tag: String) -> void:
	if not has_tag(tag):
		tags.append(tag)
		tag_added.emit(tag)
		_check_ongoing_blocks(tag)


## Removes a tag from the state.
func remove_tag(tag: String) -> void:
	if not tag in tags:
		return
	tags.erase(tag)
	tag_removed.emit(tag)
	_check_ongoing_requires(tag)


## Updates effects and attributes during each frame.
func tick(delta: float) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		if effect.duration_type == OboroEffect.Duration.DURATIONAL:
			effect.remaining -= delta
			if effect.remaining <= 0.0:
				to_remove.append(effect)
				continue
		if effect.period > 0.0:
			effect.period_elapsed += delta
			while effect.period_elapsed >= effect.period:
				effect.period_elapsed -= effect.period
				apply_modifiers_periodic(effect, effect.source_states)
	for effect in to_remove:
		remove(effect)


## Handles receiving damage and emits the damage_received signal. Called by OboroComponent.
func receive_damage(ctx: OboroDmgCtx) -> void:
	damage_received.emit(ctx)


## Removes an effect from the state and applies cleanup.
func remove(effect: OboroEffect) -> void:
	if not effect in effects:
		return
	effects.erase(effect)
	_remove_tags(effect)
	_revoke_granted_abilities(effect)
	recalculate_affected(effect)
	effect_removed.emit(effect)


## Applies instant modifiers (one-time application).
func apply_modifiers_instant(effect: OboroEffect, source: OboroStates = null) -> void:
	_apply_modifiers(effect.modifiers, effect.stacks, source)


## Applies periodic modifiers (called once per period tick).
func apply_modifiers_periodic(effect: OboroEffect, source: OboroStates = null) -> void:
	_apply_modifiers(effect.periodic_modifiers, effect.stacks, source)


## Applies tags provided and removes tags specified by an effect.
func apply_effect_tags(effect: OboroEffect) -> void:
	for tag in effect.removes_tags:
		remove_tag(tag)
	for tag in effect.provides_tags:
		add_tag(tag)


## Recalculates an attribute based on its definition and active modifiers.
func recalc_attr(attr_name: StringName) -> void:
	var attr := get_attr(attr_name)
	if not attr:
		return
	var def: OboroAttrDef = attr_defs.get(attr_name)
	var result: float = _evaluator.get_base(def, attrs) if (_evaluator and def) else attr.base_value
	var mod_ctx := OboroModifierCtx.new()
	mod_ctx.target = self
	for effect in effects:
		mod_ctx.stacks = effect.stacks
		mod_ctx.source = effect.source_states
		for mod: OboroModifier in effect.modifiers:
			if mod.target_attr == attr_name:
				result = mod.apply(result, mod_ctx)
	if def:
		if def.clamp_min != &"":
			var min_attr := get_attr(def.clamp_min)
			if min_attr:
				result = maxf(result, min_attr.value)
		if def.clamp_max != &"":
			var max_attr := get_attr(def.clamp_max)
			if max_attr:
				result = minf(result, max_attr.value)
	attr.value = result


func _check_ongoing_requires(removed_tag: String) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		for req in effect.ongoing_required_tags:
			if not has_tag(req):
				to_remove.append(effect)
				break
	for effect in to_remove:
		remove(effect)


func _check_ongoing_blocks(added_tag: String) -> void:
	var to_remove: Array[OboroEffect] = []
	for effect in effects:
		for block in effect.ongoing_blocking_tags:
			if added_tag == block or added_tag.begins_with(block + "."):
				to_remove.append(effect)
				break
	for effect in to_remove:
		remove(effect)


func _apply_modifiers(mods: Array[OboroModifier], stacks: int = 1, source: OboroStates = null) -> void:
	var mod_ctx := OboroModifierCtx.new()
	mod_ctx.target = self
	mod_ctx.stacks = stacks
	mod_ctx.source = source
	for mod: OboroModifier in mods:
		var attr := get_attr(mod.target_attr)
		if not attr:
			continue
		var result := mod.apply(attr.value, mod_ctx)
		var def: OboroAttrDef = attr_defs.get(mod.target_attr)
		if def:
			if def.clamp_min != &"":
				var min_attr := get_attr(def.clamp_min)
				if min_attr:
					result = maxf(result, min_attr.value)
			if def.clamp_max != &"":
				var max_attr := get_attr(def.clamp_max)
				if max_attr:
					result = minf(result, max_attr.value)
		attr.value = result


func _revoke_granted_abilities(effect: OboroEffect) -> void:
	for ability: OboroAbility in effect.grants_abilities:
		revoke_ability(ability.ability_name)


func _remove_tags(effect: OboroEffect) -> void:
	for tag in effect.provides_tags:
		remove_tag(tag)


## Recalculates all attributes affected by the given effect.
func recalculate_affected(effect: OboroEffect) -> void:
	var dirty: Array[StringName] = []
	for mod: OboroModifier in effect.modifiers:
		if not mod.target_attr in dirty:
			dirty.append(mod.target_attr)
	if dirty.is_empty():
		return
	## eval_orderに従って再計算することでderivedの連鎖も正しく伝播する
	if _evaluator:
		for attr_name in _evaluator.eval_order:
			recalc_attr(attr_name)
	else:
		for attr_name in dirty:
			recalc_attr(attr_name)
