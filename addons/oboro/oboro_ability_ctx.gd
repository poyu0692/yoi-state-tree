class_name OboroAbilityCtx
extends RefCounted

## The owner node that initiated the ability.
var owner: Node
## The OboroComponent managing this ability.
var oboro: OboroComponent
## Reference to the scene tree.
var tree: SceneTree
## The current state of the ability holder.
var state: OboroStates
## The effect processor for applying effects.
var effects: OboroEffectProcesser
## Custom data dictionary for game-side extensions (VFX, audio, event bus, etc).
var vars: Dictionary[Variant, Variant] = { }


## Waits for the specified duration. Use: `await ctx.wait(1.0)`.
func wait(duration: float) -> Signal:
	return tree.create_timer(duration).timeout


## Waits for damage to be received. Use: `await ctx.wait_damage()`.
func wait_damage() -> OboroDmgCtx:
	return await state.damage_received


## Waits for pre-damage-sent signal. Use: `await ctx.wait_pre_damage_sent()`.
func wait_pre_damage_sent() -> OboroDmgCtx:
	return await state.pre_damage_sent


## Waits for pre-damage-received signal. Use: `await ctx.wait_pre_damage_received()`.
func wait_pre_damage_received() -> OboroDmgCtx:
	return await state.pre_damage_received


## Waits for a specific tag to be added to the state. Use: `await ctx.wait_tag("stunned")`.
func wait_tag(tag: String) -> String:
	while true:
		var t: String = await state.tag_added
		if t == tag:
			return t
	return ""
