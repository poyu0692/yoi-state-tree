class_name OboroAttr
extends RefCounted

## Emitted when the attribute value changes.
signal value_changed(current: float, old: float)

## The current value of the attribute.
var value: float:
	get:
		return _value
	set(v):
		if _value != v:
			var old := _value
			_value = v
			value_changed.emit(_value, old)
## The base value of the attribute before modifiers.
var base_value: float
var _value: float


## Initializes the attribute with a base value.
func _init(p_base_value: float = 0.0) -> void:
	base_value = p_base_value
	_value = p_base_value
