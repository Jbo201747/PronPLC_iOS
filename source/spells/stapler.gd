extends TileModifierSpell


enum {
 SELECTING, 
 MERGING, 
}

var first_tile: Tile
var state: = SELECTING


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT]


func _use() -> void :
 state = SELECTING
 first_tile = await get_selection()
 if first_tile == null:
  _end_use()
  return

 first_tile.animation.play("pressed")

 state = MERGING

 var second_tile: Tile = await get_selection([first_tile])
 if second_tile == null:
  _end_use()
  return

 apply_to_tile(second_tile, second_tile, false, false)

 _post_use()


func _end_use():
 state = SELECTING
 super._end_use()


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 var add_capital = real_tile.has_status(TileStatus.CAPITAL) or first_tile.has_status(TileStatus.CAPITAL)
 var add_period = real_tile.has_status(TileStatus.PERIOD) or first_tile.has_status(TileStatus.PERIOD)
 var merging_from_left = first_tile.get_coord().x < real_tile.get_coord().x

 var change_tile: Tile = first_tile
 if is_preview:
  change_tile = tile
  change_tile.copy_tile(first_tile)

 if merging_from_left:
  change_tile.set_face(first_tile.face + real_tile.face)
 else:
  change_tile.set_face(real_tile.face + first_tile.face)

 change_tile.add_status(TileStatus.CRIT)
 if add_capital:
  change_tile.add_status(TileStatus.CAPITAL)
 elif add_period:
  change_tile.add_status(TileStatus.PERIOD)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.STAPLE)
  tile_board.swap_tiles(first_tile, real_tile)
  tile_board.remove_tile(real_tile, {settle = false, restock = false})
  real_tile.add_poofcloud(first_tile.get_color(), Globals.COLORS.BLEND_SMOKE)
  await Game.timeout(0.24)
  await tile_board.settle_board()
  await tile_board.fill_board()


func can_merge_tile(tile):
 return (
  tile.has_face()
  and tile.faces.size() == 1
  and not tile.is_indestructible()
  and not tile.has_any_effect(Globals.FULL_WILDCARD_EFFECTS + [TileStatus.BOMB, TileEffect.SLASHED, TileStatus.MYSTERY])
 )


func are_tiles_mergeable(tile_a, tile_b):
 if not can_merge_tile(tile_a) or not can_merge_tile(tile_b):
  return false

 if len(tile_a.face + tile_b.face) > 3:
  return false

 var a_special = tile_a.has_any_status([TileStatus.PERIOD, TileStatus.CAPITAL])
 var b_special = tile_b.has_any_status([TileStatus.PERIOD, TileStatus.CAPITAL])
 if a_special and b_special:
  return false

 if not (a_special or b_special):
  return true


 var coord_a = tile_a.get_coord()
 var coord_b = tile_b.get_coord()
 if coord_a.x < coord_b.x:
  if tile_a.has_status(TileStatus.PERIOD) or tile_b.has_status(TileStatus.CAPITAL):
   return false
 else:
  if tile_b.has_status(TileStatus.PERIOD) or tile_a.has_status(TileStatus.CAPITAL):
   return false

 return true


func has_merge_options(tile):
 var tile_coords = tile.get_coord()
 var left_tile = tile_board.get_tile_at(tile_coords + Vector2i(-1, 0))
 if left_tile != null and are_tiles_mergeable(left_tile, tile):
  return true

 var right_tile = tile_board.get_tile_at(tile_coords + Vector2i(1, 0))
 if right_tile != null and are_tiles_mergeable(right_tile, tile):
  return true

 return false


func is_tile_selectable(tile):
 if state == SELECTING:
  return has_merge_options(tile)

 for vec in [Vector2i(-1, 0), Vector2i(1, 0)]:
  var neighbor = first_tile.get_board_neighbor(vec)
  if neighbor != null and tile == neighbor and are_tiles_mergeable(tile, first_tile):
   return true

 return false


func has_special_tile_tooltip():
 return state == MERGING
