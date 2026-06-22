@tool
class_name SizeCopier extends Control


@export var source: Control
@export var offset: Vector2 = Vector2.ZERO


func _ready() -> void :
 source.resized.connect(_on_source_resized)
 _on_source_resized()


func _on_source_resized() -> void :
 custom_minimum_size = source.size + offset
 reset_size()
