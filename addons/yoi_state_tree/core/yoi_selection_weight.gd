class_name YoiSelectionWeight
extends Resource

enum Operator {
	AND, ## min() — 全考慮点の中で最も弱いものに制約される
	OR, ## max() — 最も高いスコアを採用
}

@export var weight: float = 1.0
@export var operator: Operator = Operator.AND
@export var children: Array[YoiSelectionWeight] = []


func _init() -> void:
	resource_local_to_scene = true


func evaluate(bb: YoiBlackboard) -> float:
	var raw: float
	if children.is_empty():
		raw = _score(bb)
	else:
		match operator:
			Operator.AND:
				raw = INF
				for child in children:
					raw = minf(raw, child.evaluate(bb))
				if raw == INF:
					raw = 0.0
			Operator.OR:
				raw = -INF
				for child in children:
					raw = maxf(raw, child.evaluate(bb))
				if raw == -INF:
					raw = 0.0
	return raw * weight


## 葉ノード用。サブクラスでオーバーライドしてスコアを返す。
func _score(blackboard: YoiBlackboard) -> float:
	return 1.0
