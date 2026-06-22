@tool
@abstract
class_name BGPatternEntry extends Resource

@export_range(0.0, 1.0, 0.05, "or_greater") var weight: float = 1.0


@export var repeat_delay: int = -1


func get_delay_id() -> String:
 return resource_path


func get_weight(_layer: BGLayer) -> float:
 return weight
