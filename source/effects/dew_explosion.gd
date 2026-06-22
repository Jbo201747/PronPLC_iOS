extends Node2D


func _ready():
 await $Sprite2D / AnimPlayer.animation_finished
 queue_free()


func screenshake():
 Game.screenshake(12, 0.32)
