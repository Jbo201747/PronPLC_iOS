@tool
class_name BGChunkEntry extends BGPlaceableEntry

@export var chunk: PackedScene
@export var mirrored: bool = false


func get_delay_id() -> String:
 return chunk.resource_path
