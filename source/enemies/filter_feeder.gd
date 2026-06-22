extends "res://source/enemies/bottom_feeder.gd"


const FILTER_AMOUNT = 5


func _init():
 super._init()

 suck_start_anim = "start_sucking_filter"
 id = Enemies.FILTER_FEEDER
 inherited_id = Enemies.BOTTOM_FEEDER


func display_intent():
 if moves[next_move].damage > 0:
  add_intent(Intent.ATTACK, {damage = moves[next_move].damage})

 add_intent(Intent.FILTER, {count = FILTER_AMOUNT})


func get_vacuum_tiles():
 var tiles = get_tiles({
  amount = FILTER_AMOUNT, 
  rows = [0, 1], 
 })

 rng.move.shuffle(tiles)
 return tiles
