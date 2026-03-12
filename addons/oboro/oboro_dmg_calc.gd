@abstract
class_name OboroDmgCalc
extends Resource


## Calculates a damage effect from the given damage context.
func calc(ctx: OboroDmgCtx) -> OboroEffect:
	var dmg_value := _from_dmg_ctx(ctx)
	var dmg_effect := _to_dmg_effect(dmg_value)
	return dmg_effect


## Extracts the damage value from the damage context. Override in subclasses.
@abstract
func _from_dmg_ctx(ctx: OboroDmgCtx) -> float


## Converts a damage value to an OboroEffect. Override in subclasses.
@abstract
func _to_dmg_effect(value: float) -> OboroEffect
