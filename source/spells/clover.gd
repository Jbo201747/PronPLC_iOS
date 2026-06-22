extends TileModifierSpell


enum {
 SELECTING, 
 MERGING, 
}

var first_tile: Tile
var state: = SELECTING


func _use() -> void :
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

 var merged_face: = get_merged_face(first_tile, second_tile)
 var add_capital: = (first_tile.has_status(TileStatus.CAPITAL) or second_tile.has_status(TileStatus.CAPITAL))
 var add_period: = first_tile.has_status(TileStatus.PERIOD) or second_tile.has_status(TileStatus.PERIOD)

 AudioManager.play_sound(Sounds.SPELLS.CLOVER_EAT_A)
 AudioManager.play_sound(Sounds.SPELLS.CLOVER_EAT_B)

 tile_board.swap_tiles(first_tile, second_tile)
 tile_board.remove_tile(second_tile, {settle = false, restock = false})
 second_tile.add_poofcloud(second_tile.get_color(), Globals.COLORS.BLEND_SMOKE)

 first_tile.set_face(merged_face)
 if add_capital:
  first_tile.add_status(TileStatus.CAPITAL)
 elif add_period:
  first_tile.add_status(TileStatus.PERIOD)

 await Game.timeout(0.24)
 await tile_board.settle_board()
 await tile_board.fill_board()

 _post_use()


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool) -> void :
 if not is_preview:
  return

 var merged_face: = get_merged_face(first_tile, tile)
 var add_capital: = (first_tile.has_status(TileStatus.CAPITAL) or tile.has_status(TileStatus.CAPITAL))
 var add_period: = first_tile.has_status(TileStatus.PERIOD) or tile.has_status(TileStatus.PERIOD)

 tile.copy_tile(first_tile)

 tile.set_face(merged_face)
 if add_capital:
  tile.add_status(TileStatus.CAPITAL)
 elif add_period:
  tile.add_status(TileStatus.PERIOD)




func get_merged_face(tile_a: Tile, tile_b: Tile) -> String:
 var face_ab: = tile_a.face + tile_b.face
 var face_ba: = tile_b.face + tile_a.face

 var weight_ab: float = -1.0
 var weight_ba: float = -1.0
 if len(face_ab) == 2:
  weight_ab = Letters.get_face_weight_in_list(face_ab, Letters.BIGRAMS)
  weight_ba = Letters.get_face_weight_in_list(face_ba, Letters.BIGRAMS)
 elif len(face_ab) == 3:
  weight_ab = Letters.get_face_weight_in_list(face_ab, Letters.TRIGRAMS)
  weight_ba = Letters.get_face_weight_in_list(face_ba, Letters.TRIGRAMS)


 if weight_ab > 0.0 and weight_ba > 0.0:
  if weight_ab >= weight_ba:
   return face_ab
  else:
   return face_ba
 elif weight_ab > 0.0:
  return face_ab
 elif weight_ba > 0.0:
  return face_ba

 return ""


func is_merged_face_valid(face: String) -> bool:
 if len(face) == 2 and face in Letters.BIGRAMS:
  return true
 elif len(face) == 3 and face in Letters.TRIGRAMS:
  return true
 return false


func can_merge_tile(tile: Tile) -> bool:
 return (
  tile.has_face()
  and tile.faces.size() == 1
  and not tile.is_indestructible()
  and not tile.has_any_effect([TileStatus.BOMB, TileEffect.SLASHED, TileStatus.MYSTERY])
 )


func are_tiles_mergeable(tile_a: Tile, tile_b: Tile) -> bool:
 if not can_merge_tile(tile_a) or not can_merge_tile(tile_b):
  return false

 if len(tile_a.face + tile_b.face) > 3:
  return false

 var a_special: = tile_a.has_any_status([TileStatus.PERIOD, TileStatus.CAPITAL])
 var b_special: = tile_b.has_any_status([TileStatus.PERIOD, TileStatus.CAPITAL])
 if a_special and b_special:
  return false

 if get_merged_face(tile_a, tile_b) == "":
  return false

 return true


func has_special_tile_tooltip() -> bool:
 return state == MERGING


func is_tile_selectable(tile: Tile) -> bool:
 var neighbors: Array = tile.get_board_neighbors()

 if state == MERGING:
  return first_tile in neighbors and are_tiles_mergeable(first_tile, tile)

 for neighbor in neighbors:
  if are_tiles_mergeable(tile, neighbor):
   return true

 return false


func _end_use() -> void :
 state = SELECTING
 super._end_use()
