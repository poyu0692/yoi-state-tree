@tool
class_name WriteValue
extends YoiEvaluator
## ノードまたはAutoloadから値を取得してBlackboardに書き込む。
## source / mode を組み合わせて NodeRef・Property・Method に対応する。

enum Source {NODE, AUTOLOAD}
enum Mode {NODE_REF, PROPERTY, METHOD}
enum ArgMode {LITERAL, BB_VALUE}

var blackboard_key: StringName = &"":
	set(v):
		blackboard_key = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var source: Source = Source.NODE:
	set(v):
		source = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var node_path: NodePath:
	set(v):
		node_path = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var autoload_name: String = "":
	set(v):
		autoload_name = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var mode: Mode = Mode.NODE_REF:
	set(v):
		mode = v
		if Engine.is_editor_hint():
			notify_property_list_changed()
var property_path: String = ""
var method_name: String = "":
	set(v):
		method_name = v
		_arg_modes.clear()
		_arg_values.clear()
		_arg_keys.clear()
		_arg_types.clear()
		if Engine.is_editor_hint():
			_propagate_to_args()
			notify_property_list_changed()

var _arg_modes: Array[int] = []
var _arg_values: Array = []
var _arg_keys: Array[StringName] = []
## エディタ専用: メソッドシグネチャから取得した期待型
var _arg_types: Array[int] = []

var _resolved_property: NodePath


func _inject_editor_refs(owner: Node, bb: YoiBlackboard) -> void:
	super (owner, bb)
	_propagate_to_args()


func _propagate_to_args() -> void:
	var method_info := _find_method_info(_get_editor_node())
	var arg_list: Array = method_info.get("args", []) if not method_info.is_empty() else []
	var new_size := arg_list.size()
	_arg_types.resize(new_size)
	# modes/values/keys はロード済みの値を保持するためリサイズのみ
	if _arg_modes.size() < new_size:
		_arg_modes.resize(new_size)
	if _arg_values.size() < new_size:
		_arg_values.resize(new_size)
	if _arg_keys.size() < new_size:
		_arg_keys.resize(new_size)
	for i in new_size:
		_arg_types[i] = arg_list[i]["type"]


func _get_editor_node() -> Node:
	if __editor_owner == null:
		return null
	var owner := __editor_owner.get_ref() as Node
	if owner == null:
		return null
	match source:
		Source.NODE:
			return owner.get_node_or_null(node_path) if not node_path.is_empty() else null
		Source.AUTOLOAD:
			return owner.get_node_or_null("/root/" + autoload_name) if not autoload_name.is_empty() else null
	return null


func _find_method_info(node: Node) -> Dictionary:
	if node == null or method_name.is_empty():
		return {}
	var found := node.get_method_list().filter(func(m): return m["name"] == method_name)
	return found.front() if not found.is_empty() else {}


func _get_property_list() -> Array[Dictionary]:
	var bb_keys: PackedStringArray = []
	if __editor_blackboard != null:
		for k in __editor_blackboard.get_all_keys():
			bb_keys.append(str(k))

	var bb_type := TYPE_NIL
	if __editor_blackboard != null and not blackboard_key.is_empty() \
			and __editor_blackboard.has_var(blackboard_key):
		bb_type = typeof(__editor_blackboard.get_var(blackboard_key))

	var node := _get_editor_node()

	var source_prop: Dictionary
	match source:
		Source.NODE:
			source_prop = {
				"name": "node_path",
				"type": TYPE_NODE_PATH,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT,
			}
		Source.AUTOLOAD:
			var al_names := _get_autoload_names()
			source_prop = {
				"name": "autoload_name",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM if not al_names.is_empty() else PROPERTY_HINT_NONE,
				"hint_string": ",".join(al_names),
				"usage": PROPERTY_USAGE_DEFAULT,
			}

	var props: Array[Dictionary] = [
		{
			"name": "blackboard_key",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_ENUM if not bb_keys.is_empty() else PROPERTY_HINT_NONE,
			"hint_string": ",".join(bb_keys),
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "source",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Node,Autoload",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		source_prop,
		{
			"name": "mode",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "NodeRef,Property,Method",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]

	match mode:
		Mode.PROPERTY:
			var prop_names: PackedStringArray = []
			if node != null:
				for p in node.get_property_list():
					if p["usage"] & PROPERTY_USAGE_EDITOR:
						prop_names.append(p["name"])
			props.append({
				"name": "property_path",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM if not prop_names.is_empty() else PROPERTY_HINT_NONE,
				"hint_string": ",".join(prop_names),
				"usage": PROPERTY_USAGE_DEFAULT,
			})

		Mode.METHOD:
			var method_names: PackedStringArray = []
			if node != null:
				for m in node.get_method_list():
					if not (m["flags"] & METHOD_FLAG_NORMAL):
						continue
					if (m["name"] as String).begins_with("_"):
						continue
					var ret_type: int = m["return"]["type"]
					if ret_type == TYPE_NIL:
						continue
					if bb_type != TYPE_NIL and ret_type != bb_type:
						continue
					method_names.append(m["name"])
			props.append({
				"name": "method_name",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM if not method_names.is_empty() else PROPERTY_HINT_NONE,
				"hint_string": ",".join(method_names),
				"usage": PROPERTY_USAGE_DEFAULT,
			})

			# 各引数をインラインプロパティとして展開
			for i in _arg_types.size():
				var expected_type: int = _arg_types[i]
				var arg_mode: int = _arg_modes[i] if i < _arg_modes.size() else ArgMode.LITERAL

				props.append({
					"name": "arg_%d_mode" % i,
					"type": TYPE_INT,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": "Literal,BBValue",
					"usage": PROPERTY_USAGE_DEFAULT,
				})

				if arg_mode == ArgMode.LITERAL:
					props.append({
						"name": "arg_%d_value" % i,
						"type": expected_type if expected_type != TYPE_NIL else TYPE_NIL,
						"hint": PROPERTY_HINT_NONE,
						"usage": PROPERTY_USAGE_DEFAULT | (0 if expected_type != TYPE_NIL else PROPERTY_USAGE_NIL_IS_VARIANT),
					})
				else:
					var filtered_keys: PackedStringArray = []
					if __editor_blackboard != null:
						for k in __editor_blackboard.get_all_keys():
							if expected_type == TYPE_NIL or typeof(__editor_blackboard.get_var(k)) == expected_type:
								filtered_keys.append(str(k))
					props.append({
						"name": "arg_%d_key" % i,
						"type": TYPE_STRING_NAME,
						"hint": PROPERTY_HINT_ENUM if not filtered_keys.is_empty() else PROPERTY_HINT_NONE,
						"hint_string": ",".join(filtered_keys),
						"usage": PROPERTY_USAGE_DEFAULT,
					})

	return props


func _get(property: StringName) -> Variant:
	match property:
		&"blackboard_key": return blackboard_key
		&"source": return source
		&"node_path": return node_path
		&"autoload_name": return autoload_name
		&"mode": return mode
		&"property_path": return property_path
		&"method_name": return method_name
	var s := str(property)
	if s.begins_with("arg_"):
		var rest := s.trim_prefix("arg_")
		var sep := rest.rfind("_")
		if sep >= 0:
			var idx := rest.left(sep).to_int()
			match rest.substr(sep + 1):
				"mode":
					return _arg_modes[idx] if idx < _arg_modes.size() else ArgMode.LITERAL
				"value":
					return _arg_values[idx] if idx < _arg_values.size() else null
				"key":
					return _arg_keys[idx] if idx < _arg_keys.size() else &""
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"blackboard_key":
			blackboard_key = value
			return true
		&"source":
			source = value
			return true
		&"node_path":
			node_path = value
			return true
		&"autoload_name":
			autoload_name = value
			return true
		&"mode":
			mode = value
			return true
		&"property_path":
			property_path = value
			_resolved_property = NodePath()
			return true
		&"method_name":
			method_name = value
			return true
	var s := str(property)
	if s.begins_with("arg_"):
		var rest := s.trim_prefix("arg_")
		var sep := rest.rfind("_")
		if sep >= 0:
			var idx := rest.left(sep).to_int()
			match rest.substr(sep + 1):
				"mode":
					if idx >= _arg_modes.size():
						_arg_modes.resize(idx + 1)
					_arg_modes[idx] = value
					notify_property_list_changed()
					return true
				"value":
					if idx >= _arg_values.size():
						_arg_values.resize(idx + 1)
					_arg_values[idx] = value
					return true
				"key":
					if idx >= _arg_keys.size():
						_arg_keys.resize(idx + 1)
					_arg_keys[idx] = value
					return true
	return false


func _get_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if blackboard_key.is_empty():
		warnings.append("blackboard_key is not set.")

	var path_empty := node_path.is_empty() if source == Source.NODE else autoload_name.is_empty()
	if path_empty:
		warnings.append("%s is not set." % ("node_path" if source == Source.NODE else "autoload_name"))
		return warnings

	var node := _get_editor_node()
	if node == null and __editor_owner != null:
		var label := "node_path \"%s\"" % node_path if source == Source.NODE \
			else "autoload \"%s\"" % autoload_name
		warnings.append("%s could not be resolved." % label)
		return warnings

	match mode:
		Mode.PROPERTY:
			if property_path.is_empty():
				warnings.append("property_path is not set.")
			elif node != null:
				var root_prop := property_path.get_slice(":", 0)
				if not node.get_property_list().any(func(p): return p["name"] == root_prop):
					warnings.append("property_path \"%s\" not found on node." % property_path)
		Mode.METHOD:
			if method_name.is_empty():
				warnings.append("method_name is not set.")
			elif node != null:
				if not node.has_method(method_name):
					warnings.append("method \"%s\" not found on node." % method_name)
				else:
					var method_info := _find_method_info(node)
					if not method_info.is_empty() and not blackboard_key.is_empty() \
							and __editor_blackboard != null \
							and __editor_blackboard.has_var(blackboard_key):
						var bb_type := typeof(__editor_blackboard.get_var(blackboard_key))
						var ret_type: int = method_info["return"]["type"]
						if ret_type == TYPE_NIL:
							warnings.append(
								"method \"%s\" returns void; nothing will be written." % method_name
							)
						elif ret_type != bb_type:
							warnings.append(
								"return type mismatch: \"%s\" returns %s but blackboard[%s] is %s." % [
									method_name, type_string(ret_type),
									blackboard_key, type_string(bb_type),
								]
							)
			for i in _arg_types.size():
				var expected_type: int = _arg_types[i]
				var arg_mode: int = _arg_modes[i] if i < _arg_modes.size() else ArgMode.LITERAL
				if arg_mode == ArgMode.BB_VALUE:
					var key := _arg_keys[i] if i < _arg_keys.size() else &""
					if key.is_empty():
						warnings.append("[arg_%d] key is not set." % i)
					elif __editor_blackboard != null:
						if not __editor_blackboard.has_var(key):
							warnings.append("[arg_%d] key \"%s\" not found in blackboard." % [i, key])
						elif expected_type != TYPE_NIL and typeof(__editor_blackboard.get_var(key)) != expected_type:
							warnings.append(
								"[arg_%d] type mismatch: blackboard[\"%s\"] is %s but expected %s." % [
									i, key,
									type_string(typeof(__editor_blackboard.get_var(key))),
									type_string(expected_type),
								]
							)
	return warnings


func _tick(ctx: YoiCtx) -> void:
	var node: Node
	match source:
		Source.NODE:
			node = ctx.current_state.get_node_or_null(node_path)
		Source.AUTOLOAD:
			node = ctx.current_state.get_node_or_null("/root/" + autoload_name)
	if node == null:
		return
	match mode:
		Mode.NODE_REF:
			ctx.bb.set_var(blackboard_key, node)
		Mode.PROPERTY:
			if _resolved_property.is_empty():
				_resolved_property = NodePath(property_path)
			ctx.bb.set_var(blackboard_key, node.get_indexed(_resolved_property))
		Mode.METHOD:
			var call_args := []
			for i in _arg_modes.size():
				if _arg_modes[i] == ArgMode.BB_VALUE:
					var key := _arg_keys[i] if i < _arg_keys.size() else &""
					call_args.append(ctx.bb.get_var(key))
				else:
					call_args.append(_arg_values[i] if i < _arg_values.size() else null)
			ctx.bb.set_var(blackboard_key, node.callv(method_name, call_args))


static func _get_autoload_names() -> PackedStringArray:
	var names := PackedStringArray()
	for prop in ProjectSettings.get_property_list():
		if prop["name"].begins_with("autoload/"):
			names.append(prop["name"].trim_prefix("autoload/"))
	return names
