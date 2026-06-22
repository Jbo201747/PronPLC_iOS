extends Spell


func _use():
 var selected_tile = await get_selection()

 if selected_tile == null:
  _end_use()
  return

 var row = selected_tile.get_coord().y

 var target_tiles = get_tiles({
  rows = [row], 
  sorted = true, 
 })

 if target_tiles.is_empty():
  selected_tile.animation.play("shake")
  _end_use()
  return

 for tile in target_tiles:
  tile.set_type(TileType.DEFENSE)
  tile.add_poofcloud(Globals.COLORS.SMOKE)
  await Game.timeout(0.16)

 _post_use()
