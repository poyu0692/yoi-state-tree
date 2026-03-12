class_name OboroModifierCtx
extends RefCounted

## The state applying the effect (null if not from a state).
var source: OboroStates
## The state receiving the effect.
var target: OboroStates
## Number of stacks of the effect.
var stacks: int = 1
