extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [{status = TileStatus.BOMB, wooden = true, bomb_turns = 2}]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.set_type(TileType.DAMAGE)
 tile.add_status(TileStatus.BOMB, 2)
 tile.set_face("8")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOMB_SPAWN)
  tile.add_poofcloud(Globals.COLORS.SMOKE)


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and not (tile.has_status(TileStatus.BOMB) and tile.only_face_is("8"))
