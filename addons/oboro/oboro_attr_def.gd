@tool
class_name OboroAttrDef
extends Resource

## The name of the attribute.
@export var attr_name: StringName = &"":
	set(v):
		if attr_name != v:
			resource_name = v
			attr_name = v
## The initial base value of the attribute.
@export var base_value := 0.0
## Minimum clamping attribute (e.g., "strength"). If empty, no min clamping is applied.
@export var clamp_min: StringName = &""
## Maximum clamping attribute (e.g., "max_health"). If empty, no max clamping is applied.
@export var clamp_max: StringName = &""
@export_group("Derived")
## Derived formula for calculating this attribute
##(e.g., "(hoge * 0.2) + huga", "(strength * 0.2) + 1.2")
##Empty to use base value only.
@export_multiline() var derived_formula: String = ""
