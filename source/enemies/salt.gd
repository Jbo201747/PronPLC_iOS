extends "res://source/enemies/umami.gd"


func _init():
 super._init()
 id = Enemies.SALT
 inherited_id = Enemies.UMAMI

 lash_anim = "lash_salt"

 moves.lash = {
  damage = {
   0: 5, 
   2: 6, 
   3: 8, 
  }, 
  next = "chain", 
 }
