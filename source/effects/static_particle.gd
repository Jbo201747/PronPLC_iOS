extends Node2D


func _ready():
 await %AnimPlayer.animation_finished
 get_parent().remove_child(self)
 queue_free()
