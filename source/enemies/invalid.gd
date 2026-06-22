extends "res://source/enemies/prodigy.gd"


func _init():
 super._init()
 id = Enemies.INVALID
 inherited_id = Enemies.PRODIGY
 moves.wail.mystery = 1


func add_mystery_intent() -> void :
 add_intent(Intent.MYSTERY_CRIT, {count = moves.wail.mystery, double = true})


func get_mystery_face_options() -> Array:
 return Letters.DOUBLE_LETTERS


func get_base_value_pool() -> Array[int]:
 return [2, 4]


func handle_mystery(apply_to: Array, face, hit_index):
 for tile in apply_to:
  if hit_index == 0:
   apply_mystery(tile, face[0])
  else:
   apply_mystery(tile, face)
