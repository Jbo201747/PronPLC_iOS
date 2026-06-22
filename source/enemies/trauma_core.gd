extends "res://source/enemies/age_regressor.gd"


func _init():
 super._init()
 id = Enemies.TRAUMA_CORE
 inherited_id = Enemies.AGE_REGRESSOR

 moves.big_word.scrabble_pools = [
  [1], 
  [-99, 1, 1, -99], 
  [-99, 1], 
  [1], 
 ]
