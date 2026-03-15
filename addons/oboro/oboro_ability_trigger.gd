class_name OboroAbilityTrigger
extends Resource

enum Event {
	TAG_ADDED,
	TAG_REMOVED,
	DAMAGE_RECEIVED,
	DAMAGE_SENT,
	EFFECT_APPLIED,
}

## The event that fires this trigger.
var event: Event = Event.TAG_ADDED:
	set(v):
		event = v
		notify_property_list_changed()
## Tag filter for TAG_ADDED / TAG_REMOVED events. Empty means any tag matches.
var tag_filter: String = ""
## Tags the state must have when this trigger fires.
var required_tags: Array[String] = []
## Tags the state must NOT have when this trigger fires.
var blocking_tags: Array[String] = []
## Attribute conditions the state must satisfy when this trigger fires.
var attr_conditions: Array[OboroAbilityCondition] = []


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = [
		{
			"name": "event",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "TAG_ADDED,TAG_REMOVED,DAMAGE_RECEIVED,DAMAGE_SENT,EFFECT_APPLIED",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]
	if event == Event.TAG_ADDED or event == Event.TAG_REMOVED:
		props.append({
			"name": "tag_filter",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
	props.append_array([
		{
			"name": "Fire Conditions",
			"type": TYPE_NIL,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_GROUP,
		},
		{
			"name": "required_tags",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d:" % TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "blocking_tags",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d:" % TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "attr_conditions",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%s:OboroAbilityCondition" % [TYPE_OBJECT, "OboroAbilityCondition"],
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	])
	return props


func _get(property: StringName) -> Variant:
	match property:
		&"event": return event
		&"tag_filter": return tag_filter
		&"required_tags": return required_tags
		&"blocking_tags": return blocking_tags
		&"attr_conditions": return attr_conditions
	return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"event":
			event = value
			return true
		&"tag_filter":
			tag_filter = value
			return true
		&"required_tags":
			required_tags = value
			return true
		&"blocking_tags":
			blocking_tags = value
			return true
		&"attr_conditions":
			attr_conditions = value
			return true
	return false


## Returns true when the trigger's conditions are satisfied.
## fired_tag is the tag string for TAG_ADDED / TAG_REMOVED events.
func check(state: OboroStates, fired_tag: String = "") -> bool:
	# tag_filter: empty matches all; otherwise use OboroStates prefix logic
	if tag_filter != "":
		var prefix := tag_filter + "."
		if fired_tag != tag_filter and not fired_tag.begins_with(prefix):
			return false
	for req in required_tags:
		if not state.has_tag(req):
			return false
	for block in blocking_tags:
		if state.has_tag(block):
			return false
	for cond: OboroAbilityCondition in attr_conditions:
		if not cond.check(state):
			return false
	return true
