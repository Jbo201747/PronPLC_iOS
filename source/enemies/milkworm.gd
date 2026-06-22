extends "res://source/enemies/bookworm.gd"


func _init():
 super._init()
 id = Enemies.MILKWORM
 inherited_id = Enemies.BOOKWORM

 fireball_sound = Sounds.BOOKWORM.MILKWORM_FIREBALL
 fireball_final_sound = Sounds.BOOKWORM.MILKWORM_FIREBALL_FINAL
 moves.purify.status = TileStatus.GUNK
 moves.purify.exclude_rows = [0]
 moves.purify.spicy = {
  0: 6, 
  1: 7, 
  2: 9, 
  3: 10, 
 }
 Fireball = load("res://source/effects/gunkball.tscn")
