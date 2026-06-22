extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileEffect.SLASHED]


func apply_to_tile(tile: Tile, real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 if is_preview:
  tile.set_slashed([real_tile.face, "?"])
 else:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  tile.apply_slashed(rng.spell)
  tile.add_poofcloud(Globals.COLORS.CHASER_PINK)


func is_tile_selectable(tile: Tile):
 return tile.is_single_letter(false, true) and not tile.has_status(TileStatus.MYSTERY)
