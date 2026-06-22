extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.CANDY)
 tile.remove_face_statuses()
 tile.set_type(TileType.DAMAGE)
 tile.set_face("v")

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func _use():
 var first_tile = await get_selection()
 if first_tile == null:
  _end_use()
  return

 first_tile.animation.play("pressed")

 var second_tile = await get_selection([first_tile])
 if second_tile == null:
  _end_use()
  return

 apply_to_tile(first_tile, first_tile, false, false)
 apply_to_tile(second_tile, second_tile, false, false)

 _post_use()


func is_tile_selectable(tile: Tile):
 return (
  not tile.has_harmful_status()
  and not (tile.has_status(TileStatus.CANDY) and tile.only_face_is("v") and tile.is_type(TileType.DAMAGE))
  and not tile.is_space()
 )
