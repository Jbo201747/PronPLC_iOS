extends "res://source/enemies/noppy.gd"


func _init():
 super._init()

 id = Enemies.SOPPY
 inherited_id = Enemies.NOPPY

 ash_letter = "mi"
 fish_chance = 0.4
 moves.dream.ash = 5
