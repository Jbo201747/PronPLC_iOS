extends Node2D


var velocity = Vector2(0, 0)
@onready var sprite = $Sprite


func _ready():
 await $AnimPlayer.animation_finished
 get_parent().remove_child(self)
 queue_free()


func clone(node):
 CopyUtil.copy_full(node, sprite)



















 sprite.z_index -= 1
