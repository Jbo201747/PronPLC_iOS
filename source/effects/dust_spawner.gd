extends Node2D


var Dust = preload("res://source/effects/dash_dust.tscn")


func spawn_dust():
 var dust = Dust.instantiate()
 Game.main.add_child(dust)
 dust.global_position = global_position
