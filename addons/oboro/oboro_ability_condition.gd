class_name OboroAbilityCondition
extends Resource

enum Operator {
	EQUAL,
	NOT_EQUAL,
	GRETER_THAN,
	LESS_THAN,
	GREATRER_THAN_OR_EQUAL,
	LESS_THAN_OR_EQUAL,
}

## Left-hand side attribute name to compare.
@export var left_attr: StringName
## Operator for the comparison.
@export var operator: Operator = Operator.GREATRER_THAN_OR_EQUAL
## Right-hand side attribute name. If empty, uses right_value as absolute value. Otherwise uses right_attr.value * right_value.
@export var right_attr: StringName = &""
## Right-hand side value or multiplier.
@export var right_value: float = 0.0


## Evaluates the condition against the given states.
func check(states: OboroStates) -> bool:
	var lhs := states.get_attr(left_attr)
	if not lhs:
		return false
	var rhs: float
	if right_attr == &"":
		rhs = right_value
	else:
		var rhs_a := states.get_attr(right_attr)
		if not rhs_a:
			return false
		rhs = rhs_a.value * right_value
	match operator:
		Operator.EQUAL:
			return is_equal_approx(lhs.value, rhs)
		Operator.NOT_EQUAL:
			return lhs.value != rhs
		Operator.LESS_THAN:
			return lhs.value < rhs
		Operator.GREATRER_THAN_OR_EQUAL:
			return lhs.value >= rhs
		Operator.GRETER_THAN:
			return lhs.value > rhs
		Operator.LESS_THAN_OR_EQUAL:
			return lhs.value <= rhs
	return false
