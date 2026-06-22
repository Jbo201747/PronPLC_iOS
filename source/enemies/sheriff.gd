extends "res://source/enemies/new_cop.gd"


func _init():
 super._init()
 id = Enemies.SHERIFF
 inherited_id = Enemies.NEW_COP
 pop_on_deflate = true
 moves.warning_shot.holes = 2
 moves.warning_shot.ash = true
