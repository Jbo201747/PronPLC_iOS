extends "res://source/enemies/herarra.gd"


func _init():
 super._init()
 id = Enemies.JUVENILE
 inherited_id = Enemies.HERARRA
 moves.all.bruise = {
  0: 2, 
  1: 3, 
  2: 4, 
  3: 5, 
 }
 moves.all.second_status = TileStatus.BLEED
 moves.shredder.damage = 0
 moves.breakdown.damage = 0


func display_intent():
 add_intent(Intent.APPLY_STATUS, {status = TileStatus.BLEED, count = moves.all.bruise})
 add_intent(Intent.APPLY_STATUS, {status = TileStatus.BRUISE, count = moves.all.bruise})
