extends TileModifierSpell


var tile_poofcloud_color = Globals.COLORS.SMOKE


func set_status_tooltips():
 status_tooltips = [TileStatus.HOLE]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.apply_hole( not is_preview)

 if has_curse(CURSE.CURSED):
  tile.add_status(TileStatus.CURSED)

 if not is_preview:
  tile.add_poofcloud(tile_poofcloud_color)
  AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)


func is_tile_selectable(tile):
 return not tile.is_space() and not tile.has_harmful_status()
