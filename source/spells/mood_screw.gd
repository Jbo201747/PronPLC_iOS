extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.SCREW]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.SCREW)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.SCREW)
  tile.animation.play("shake")


func is_tile_selectable(tile: Tile):
 return not tile.is_space() and tile_board.get_column(tile.get_coord().x)[0] == tile
