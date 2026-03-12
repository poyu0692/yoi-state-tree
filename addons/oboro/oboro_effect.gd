class_name OboroEffect
extends Resource

enum Duration {
	INSTANT,
	DURATIONAL,
	PERMANENT,
}
enum Stacking {
	DENY, ## 既存があれば新規を無視
	OVERRIDE, ## 既存を新規で上書き（duration リセット）
	AGGREGATE, ## スタック数を加算（max_stacks まで）
	SEPARATE, ## 独立したインスタンスとして共存
}
enum StackDuration {
	RESET, ## スタック時に duration をリセット
	ADD, ## duration を加算
	MAX, ## 長い方を採用
}

## The duration type of this effect (INSTANT, DURATIONAL, PERMANENT).
@export var duration_type := Duration.INSTANT
## Duration in seconds. Only used for DURATIONAL effects.
@export_range(0.0, 999.0, 0.1, "suffix:s") var duration := 0.0
## Modifiers applied to attributes when the effect is applied.
@export var modifiers: Array[OboroModifier] = []
@export_group("Abilities")
## Abilities granted when this effect is applied.
@export var grants_abilities: Array[OboroAbility] = []
## Ability names to revoke when this effect is applied.
@export var revokes_abilities_by_name: Array[String] = []
## Ability tags to revoke when this effect is applied. All abilities with matching tags are removed.
@export var revokes_abilities_by_tag: Array[String] = []
@export_group("Condition Tags")
## Required tags for applying this effect (full match or prefix match).
@export var required_tags: Array[String] = []
## Blocking tags that prevent this effect from being applied (any match blocks).
@export var blocking_tags: Array[String] = []
## Tags that must remain present for the effect to persist. Removed if any query fails.
@export var ongoing_required_tags: Array[String] = []
## Tags that remove the effect if matched while it's active.
@export var ongoing_blocking_tags: Array[String] = []
@export_group("Output Tags")
## Tags added when this effect is applied.
@export var provides_tags: Array[String] = []
## Tags removed when this effect is applied.
@export var removes_tags: Array[String] = []
@export_group("Periodic")
## Periodic tick interval in seconds. Set to 0.0 to disable periodic ticks.
@export_range(0.0, 999.0, 0.1, "suffix:s") var period := 0.0
## If true, periodic modifiers execute immediately on apply. If false, wait for first period.
@export var execute_on_apply := false
## Modifiers applied at each periodic tick.
@export var periodic_modifiers: Array[OboroModifier] = []
@export_group("Stacking")
## Stacking policy for multiple instances of this effect.
@export var stacking := Stacking.DENY
## Maximum number of stacks. Only used for AGGREGATE stacking.
@export var max_stacks := 1
## How the duration changes when stacked. Only used for AGGREGATE + DURATIONAL.
@export var stack_duration := StackDuration.RESET

## Remaining duration for DURATIONAL effects at runtime. Resource instances should be duplicated.
var remaining: float = -1.0
var period_elapsed: float = 0.0
var stacks: int = 1
## The source effect definition this instance was created from. Used for stacking identification.
var _source: OboroEffect = null
## Source OboroStates for formula evaluation. Set on instances at apply time.
var source_states: OboroStates = null
