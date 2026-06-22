extends "res://source/enemies/fat_cat.gd"


func _init():
 super._init()
 id = Enemies.PURRGEOISIE
 inherited_id = Enemies.FAT_CAT

 moves.all.can_leave = false
 moves.knead.bleed = {
  0: 4, 
  2: 5, 
  3: 6, 
 }
 knead_status = TileStatus.BRUISE
 knead_type_priority = TileType.DAMAGE
 fish_chance = 0.3
