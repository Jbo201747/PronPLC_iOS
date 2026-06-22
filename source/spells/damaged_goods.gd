extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.HOLE, TileStatus.BRUISE]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.BRUISE)
 tile.apply_hole( not is_preview)

 if not is_preview:
  tile.add_poofcloud(tile.get_color())
  AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)

  var bruise_targets = get_tiles({
   amount = 8, 
   type = TileType.DAMAGE, 
   effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
  })

  for target_tile in bruise_targets:
   await Game.timeout(0.08)

   target_tile.add_status(TileStatus.BRUISE)
   target_tile.add_poofcloud(target_tile.get_color())


func is_tile_selectable(tile):
 return not tile.is_space() and not tile.is_indestructible()
