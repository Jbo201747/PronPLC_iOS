extends Spell


var swapping: = false


func get_tooltip_context():
 return {swapping = swapping}


func _use():
 swapping = false

 var tile_a = await get_selection()

 if tile_a == null:
  _end_use()
  return

 tile_a.animation.play("pressed")

 swapping = true
 update_banner_label()

 var tile_b = await get_selection([tile_a])

 if tile_b == null:
  _end_use()
  return

 if tile_a == tile_b:
  tile_a.animation.play("shake")
  _end_use()
  return

 await tile_board.swap_tiles(tile_a, tile_b, 0.08, 0.04)

 _post_use()
