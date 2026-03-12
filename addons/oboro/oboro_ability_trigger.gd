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
@export var event: Event = Event.TAG_ADDED
## Tag filter for TAG_ADDED / TAG_REMOVED events. Empty means any tag matches.
@export var tag_filter: String = ""
@export_group("Fire Conditions")
## Tags the state must have when this trigger fires.
@export var required_tags: Array[String] = []
## Tags the state must NOT have when this trigger fires.
@export var blocking_tags: Array[String] = []
## Attribute conditions the state must satisfy when this trigger fires.
@export var attr_conditions: Array[OboroAbilityCondition] = []


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
