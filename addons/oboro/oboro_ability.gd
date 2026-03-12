@abstract
class_name OboroAbility
extends Resource

signal ended

enum TriggerMode {
	ANY, ## Invoke when at least one trigger fires and its conditions pass.
	ALL, ## Invoke only when every trigger has fired (and passed) since the last reset.
}

## Cooldown duration in seconds. Set to 0.0 for no cooldown.
@export_range(0.0, 999.0, 0.1, "suffix:s") var cooldown := 0.0
## Unique identifier for this ability.
@export var ability_name := &""
## Tags applied to the state while this ability is active. Used for matching revokes_abilities_by_tag.
@export var active_tags: Array[String] = []
@export_group("Conditions")
## Required tags for activation (full match or prefix match).
@export var required_tags: Array[String] = []
## Blocking tags that prevent activation (any match blocks).
@export var blocking_tags: Array[String] = []
## Attribute conditions required for activation.
@export var attr_conditions: Array[OboroAbilityCondition] = []
@export_group("Triggers")
## ANY: invoke when at least one trigger fires and passes. ALL: invoke only when every trigger has fired (and passed) since last reset.
@export var trigger_mode: TriggerMode = TriggerMode.ANY
## Triggers that automatically call invoke() when fired. Evaluated with trigger_mode.
@export var triggers: Array[OboroAbilityTrigger] = []
@export_group("Override")
## Tag applied during cooldown. If empty, "CoolDown." + ability_name is used.
@export var cooldown_tag := &""

# Tracks which triggers have fired for ALL mode.
var _trigger_fired: Array[bool] = []
# Stored connections for cleanup on revoke: Array of [signal_ref, callable]
var _trigger_connections: Array = []


## Checks if this ability can be activated given the current state and conditions.
func can_activate(ctx: OboroAbilityCtx) -> bool:
	for req in required_tags:
		if not ctx.state.has_tag(req):
			return false
	for block in blocking_tags:
		if ctx.state.has_tag(block):
			return false
	for cond: OboroAbilityCondition in attr_conditions:
		if not cond.check(ctx.state):
			return false
	var cd_tag := _cd_tag()
	if ctx.state.has_tag(cd_tag):
		return false
	return true


## Template method that applies cooldown, calls _pre_activate, then _activate. Do not override.
func invoke(ctx: OboroAbilityCtx) -> void:
	if cooldown > 0.0:
		var cd_effect := OboroEffect.new()
		cd_effect.duration_type = OboroEffect.Duration.DURATIONAL
		cd_effect.duration = cooldown
		cd_effect.provides_tags = [_cd_tag()]
		ctx.effects.apply(ctx.state, cd_effect)
	_on_pre_activated(ctx)
	_activate(ctx)


## Ends the ability and emits the ended signal. Call from external code to properly deactivate.
func end() -> void:
	_on_deactivated()
	ended.emit()


## Connects data-driven triggers then calls _on_granted. Called by OboroStates. Do not override.
func grant(ctx: OboroAbilityCtx) -> void:
	_trigger_fired.resize(triggers.size())
	_trigger_fired.fill(false)
	_trigger_connections.clear()
	for i in triggers.size():
		var trigger: OboroAbilityTrigger = triggers[i]
		var sig: Signal
		var cb: Callable
		match trigger.event:
			OboroAbilityTrigger.Event.TAG_ADDED:
				cb = func(tag: String) -> void: _on_trigger_tag(i, tag, ctx)
				sig = ctx.state.tag_added
			OboroAbilityTrigger.Event.TAG_REMOVED:
				cb = func(tag: String) -> void: _on_trigger_tag(i, tag, ctx)
				sig = ctx.state.tag_removed
			OboroAbilityTrigger.Event.DAMAGE_RECEIVED:
				cb = func(_dmg: OboroDmgCtx) -> void: _on_trigger_simple(i, ctx)
				sig = ctx.state.damage_received
			OboroAbilityTrigger.Event.DAMAGE_SENT:
				cb = func(_dmg: OboroDmgCtx) -> void: _on_trigger_simple(i, ctx)
				sig = ctx.state.pre_damage_sent
			OboroAbilityTrigger.Event.EFFECT_APPLIED:
				cb = func(_eff: OboroEffect) -> void: _on_trigger_simple(i, ctx)
				sig = ctx.state.effect_applied
		sig.connect(cb)
		_trigger_connections.append([sig, cb])
	_on_granted(ctx)


## Disconnects triggers then calls _on_revoked. Called by OboroStates. Do not override.
func revoke(ctx: OboroAbilityCtx) -> void:
	for pair in _trigger_connections:
		var sig: Signal = pair[0]
		var cb: Callable = pair[1]
		if sig.is_connected(cb):
			sig.disconnect(cb)
	_trigger_connections.clear()
	_trigger_fired.clear()
	_on_revoked(ctx)


## Called after triggers are connected. Override to connect additional signals for reactive behavior.
func _on_granted(ctx: OboroAbilityCtx) -> void:
	pass


## Called before triggers are disconnected. Override to disconnect additional signals.
func _on_revoked(ctx: OboroAbilityCtx) -> void:
	pass


## Optional hook called before _activate (e.g., for resource consumption or effects). Override in subclasses.
func _on_pre_activated(ctx: OboroAbilityCtx) -> void:
	pass


## Core activation logic. Override in subclasses to implement ability behavior.
func _activate(ctx: OboroAbilityCtx) -> void:
	pass


## Cleanup logic on deactivation. Override in subclasses for custom behavior.
func _on_deactivated() -> void:
	pass


# --- private ---
func _cd_tag() -> String:
	if cooldown_tag != &"":
		return cooldown_tag
	return "cooldown." + str(ability_name)


func _on_trigger_tag(index: int, tag: String, ctx: OboroAbilityCtx) -> void:
	if triggers[index].check(ctx.state, tag):
		_evaluate_triggers(index, ctx)


func _on_trigger_simple(index: int, ctx: OboroAbilityCtx) -> void:
	if triggers[index].check(ctx.state):
		_evaluate_triggers(index, ctx)


func _evaluate_triggers(fired_index: int, ctx: OboroAbilityCtx) -> void:
	match trigger_mode:
		TriggerMode.ANY:
			invoke(ctx)
		TriggerMode.ALL:
			_trigger_fired[fired_index] = true
			for fired in _trigger_fired:
				if not fired:
					return
			_trigger_fired.fill(false)
			invoke(ctx)
