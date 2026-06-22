extends "res://source/enemies/xrafstar.gd"


func _init():
 super._init()

 id = Enemies.PSEUD
 inherited_id = Enemies.XRAFSTAR

 moves.extrude = {
  poop = {
   0: 8, 
   2: 10, 
  }, 
  status = TileStatus.POOP, 
  target = "top", 
  next = "pollute", 
  intent_name = "big_intestine", 
 }
 moves.pollute = {
  poison = {
   0: 5, 
   1: 6, 
  }, 
  damage = {
   0: 4, 
   1: 5, 
   2: 6, 
   3: 8, 
  }, 
  status = TileStatus.POOP, 
  target = "bottom", 
  next = "extrude", 
  intent_name = "small_intestine", 
 }
