@tool
@abstract
class_name YoiSensor
extends Resource


## エディタ警告を返す。YoiState._get_configuration_warnings() から収集される。
func _get_warnings(owner: Node) -> PackedStringArray:
	return PackedStringArray()


@abstract
func _tick(ctx: YoiCtx) -> void
