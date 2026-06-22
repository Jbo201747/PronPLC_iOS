extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 var was_bleed: = tile.has_status(TileStatus.BLEED)
 tile.remove_face_statuses()
 tile.add_status(TileStatus.CANDY)
 tile.set_type(TileType.DEFENSE)
 tile.set_face("x")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  if was_bleed:
   tile.add_poofcloud(Globals.COLORS.BLOOD)
  else:
   tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile: Tile):
 return (
  (tile.has_status(TileStatus.BLEED) or not tile.has_harmful_status())
  and not (tile.has_status(TileStatus.CANDY) and tile.only_face_is("x") and tile.is_type(TileType.DEFENSE))
  and not tile.is_space()
 )
