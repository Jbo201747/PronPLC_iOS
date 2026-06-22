extends TileModifierSpell


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 if tile.is_type(TileType.DAMAGE):
  tile.set_type(TileType.DEFENSE)

 elif tile.is_type(TileType.DEFENSE):
  tile.set_type(TileType.DAMAGE)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  tile.add_poofcloud(tile.get_color(), Globals.COLORS.SMOKE)
