class_name OboroDefaultDmgCalc
extends OboroDmgCalc

## The attribute to reduce when applying damage (default: "hp").
@export var target_attr: StringName = &"hp"


## Extracts the damage value directly from the context.
func _from_dmg_ctx(ctx: OboroDmgCtx) -> float:
	return ctx.damage


## Creates a modifier effect that reduces the target attribute by the damage value.
func _to_dmg_effect(value: float) -> OboroEffect:
	var effect := OboroEffect.new()
	var mod := OboroModifier.create(target_attr, OboroModifier.Operator.SUB, value)
	effect.modifiers.append(mod)
	return effect
