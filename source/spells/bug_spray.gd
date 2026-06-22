class_name BugSpray extends Spell


static func spray_tile(tile: Tile) -> void :
 AudioManager.play_sound(Sounds.SPELLS.SPRAY_SHORT)

 var target_tiles = [tile] + tile.get_board_neighbors()
 var destroying_tiles: Array[Tile] = []
 for target: Tile in target_tiles:
  if target.destroyed_by_spray():
   destroying_tiles.append(target)

 if not destroying_tiles.is_empty():
  await Game.word_builder.remove_tiles()
  await Game.tile_board.wait_for_idle_tiles()

  Game.tile_board.remove_tiles(destroying_tiles, {
   delete_tiles = false, 
   settle = false, 
   restock = false, 
  })


 for target: Tile in target_tiles:
  if target not in destroying_tiles:
   var statuses_to_remove: Array[String] = []
   for status in target.get_statuses():
    if not status.is_spray_exempt():
     statuses_to_remove.append(status.id)

   target.remove_statuses(statuses_to_remove)

   if target.faces.size() > 1:
    target.set_face(target.face)

  target.add_poofcloud(Globals.COLORS.ICE)

  if target in destroying_tiles:
   AudioManager.play_sound(Sounds.TILE.COAL_CRUMBLE)
   target.clear(false)

  await Game.timeout(0.08)

 if not destroying_tiles.is_empty():
  await Game.tile_board.settle_board()
  await Game.tile_board.fill_board()


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 await spray_tile(tile)

 _post_use()
