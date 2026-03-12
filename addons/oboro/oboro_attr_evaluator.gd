class_name OboroAttrEvaluator
extends RefCounted

## Topologically sorted order of attribute evaluation for derived formulas.
var eval_order: Array[StringName] = []
## Parsed Expression objects for attributes with derived formulas.
var _expressions: Dictionary[StringName, Expression] = { }
## Variable names for each Expression (in attribute name order).
var _expr_var_names: Dictionary[StringName, PackedStringArray] = { }
## Dependency graph: attribute name -> array of dependent attribute names.
var _deps: Dictionary[StringName, Array] = { }


## Sets up the evaluator with the given attribute definitions and parses derived formulas.
func setup(defs: Array[OboroAttrDef]) -> void:
	_deps.clear()
	_expressions.clear()
	_expr_var_names.clear()

	var all_names: Array[StringName] = []
	for def in defs:
		all_names.append(def.attr_name)
		_deps[def.attr_name] = []

	for def in defs:
		if def.derived_formula.is_empty():
			continue
		var deps: Array = []
		var var_names: PackedStringArray = []
		for name in all_names:
			if _is_word_in_expr(str(name), def.derived_formula):
				deps.append(name)
				var_names.append(str(name))
		_deps[def.attr_name] = deps

		var expr := Expression.new()
		if expr.parse(def.derived_formula, var_names) == OK:
			_expressions[def.attr_name] = expr
			_expr_var_names[def.attr_name] = var_names

	var visited: Dictionary = { }
	var in_stack: Dictionary = { }
	eval_order.clear()
	for name in all_names:
		_visit(name, visited, in_stack)


## Evaluates the derived formula and returns the base value. Returns def.base_value if no derived formula exists.
func get_base(def: OboroAttrDef, attrs: Dictionary) -> float:
	if not _expressions.has(def.attr_name):
		return def.base_value
	var expr: Expression = _expressions[def.attr_name]
	var var_names: PackedStringArray = _expr_var_names[def.attr_name]
	var values: Array = []
	for vname in var_names:
		var attr: OboroAttr = attrs.get(StringName(vname))
		values.append(attr.value if attr else 0.0)
	var result = expr.execute(values)
	if expr.has_execute_failed():
		return def.base_value
	return float(result)


# --- private ---
## Checks if a word appears in an expression as a complete word (not a substring).
func _is_word_in_expr(word: String, expr: String) -> bool:
	var re := RegEx.new()
	re.compile("(?<!\\w)" + word + "(?!\\w)")
	return re.search(expr) != null


func _visit(name: StringName, visited: Dictionary, in_stack: Dictionary) -> void:
	if in_stack.get(name, false):
		push_error("OboroAttrEvaluator: circular dependency detected at '%s'" % str(name))
		return
	if visited.get(name, false):
		return
	in_stack[name] = true
	for dep: StringName in _deps.get(name, []):
		_visit(dep, visited, in_stack)
	in_stack.erase(name)
	visited[name] = true
	eval_order.append(name)
