extends Node2D


@onready var sprite = $Sprite2D
@onready var anim_player = $AnimPlayer


func _ready():
 sprite.frame = randi_range(0, 3)

 await anim_player.animation_finished
 get_parent().remove_child(self)
 queue_free()
