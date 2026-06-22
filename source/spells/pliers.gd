extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [{status = TileStatus.ENHANCED, wooden = true}, TileStatus.BLEED]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.ENHANCED)

 if is_preview:
  return

 tile.add_poofcloud(Globals.COLORS.SMOKE)

 var bleed_left = 1
 var neighbor_tiles = tile.get_board_neighbors()
 rng.spell.shuffle(neighbor_tiles)

 for neighbor in neighbor_tiles:
  if not neighbor.has_status(TileStatus.DEFAULT) or neighbor.is_space():
   continue

  await Game.timeout(0.16)

  neighbor.add_status(TileStatus.BLEED)
  neighbor.add_poofcloud(neighbor.get_color())

  bleed_left -= 1
  if bleed_left == 0:
   break


func is_tile_selectable(tile):
 return (tile.is_type(TileType.DAMAGE)
   and not tile.has_harmful_status()
   and tile.has_face()
   and not tile.has_status(TileStatus.ENHANCED)
   )
