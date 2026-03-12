class_name OboroModifier
extends Resource

enum Operator { ADD, SUB, MUL, DIV }

@export var target_attr: StringName = &""
@export var operator: Operator = Operator.ADD
@export var value: float = 0.0
@export_group("Magnitude")
@export_multiline var magnitude_formula: String = ""

# runtime cache (not exported)
var _expr: Expression = null
var _expr_var_names: PackedStringArray = []
var _expr_parsed: bool = false


static func create(p_target_attr: StringName, p_operator: Operator, p_value: float) -> OboroModifier:
	var mod := new()
	mod.target_attr = p_target_attr
	mod.operator = p_operator
	mod.value = p_value
	return mod


static func create_formula(p_target_attr: StringName, p_operator: Operator, p_formula: String) -> OboroModifier:
	var mod := new()
	mod.target_attr = p_target_attr
	mod.operator = p_operator
	mod.magnitude_formula = p_formula
	return mod


func apply(base: float, ctx: OboroModifierCtx) -> float:
	var mag := _resolve_magnitude(ctx)
	match operator:
		Operator.ADD:
			return base + mag
		Operator.SUB:
			return base - mag
		Operator.MUL:
			return base * mag
		Operator.DIV:
			return base / mag if mag != 0.0 else base
	return base


func _resolve_magnitude(ctx: OboroModifierCtx) -> float:
	if magnitude_formula.is_empty():
		return value
	if not _expr_parsed:
		_expr_parsed = true
		var preprocessed := magnitude_formula \
		.replace("source.", "source_") \
		.replace("target.", "target_")
		var re := RegEx.new()
		re.compile("\\b(source_\\w+|target_\\w+|stacks)\\b")
		var found: PackedStringArray = []
		for m in re.search_all(preprocessed):
			var vname := m.get_string()
			if not vname in found:
				found.append(vname)
		_expr_var_names = found
		_expr = Expression.new()
		if _expr.parse(preprocessed, _expr_var_names) != OK:
			push_warning("OboroModifier: failed to parse formula '%s'" % magnitude_formula)
			_expr = null
	if _expr == null:
		return value
	var values: Array = []
	for vname: String in _expr_var_names:
		if vname == "stacks":
			values.append(float(ctx.stacks))
		elif vname.begins_with("source_"):
			var attr := ctx.source.get_attr(StringName(vname.substr(7))) if ctx.source else null
			values.append(attr.value if attr else 0.0)
		elif vname.begins_with("target_"):
			var attr := ctx.target.get_attr(StringName(vname.substr(7))) if ctx.target else null
			values.append(attr.value if attr else 0.0)
		else:
			values.append(0.0)
	var result = _expr.execute(values)
	if _expr.has_execute_failed():
		return value
	return float(result)
