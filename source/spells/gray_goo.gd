extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 var target_tiles = get_tiles({
  amount = 1, 
  exclude_tiles = [tile], 
 })

 if target_tiles.is_empty():
  tile.animation.play("shake")
  _end_use()
  return

 target_tiles[0].copy_tile(tile)
 target_tiles[0].add_poofcloud(tile.get_color())

 _post_use()
