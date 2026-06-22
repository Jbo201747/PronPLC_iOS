extends TileModifierSpell


var active_suit: String = ""


func set_status_tooltips():
 status_tooltips = [TileStatus.SPICY, TileEffect.SUIT]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.SPICY)
 tile.set_face(active_suit)

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func _use():
 active_suit = tile_board.get_absent_suits(rng.spell)[0]

 var first_tile = await get_selection()
 if first_tile == null:
  _end_use()
  return

 first_tile.animation.play("pressed")

 var second_tile = await get_selection([first_tile])
 if second_tile == null:
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.MATCH_BOX)
 apply_to_tile(first_tile, first_tile, false, false)
 apply_to_tile(second_tile, second_tile, false, false)

 _post_use()


func is_tile_selectable(tile: Tile):
 return (
  not tile.has_harmful_status()
  and not (tile.has_effect(TileEffect.SUIT) and tile.is_single_letter(true, false))
  and not tile.is_space()
 )
