extends TileModifierSpell

enum {
 COPYING, 
 PASTING
}

var state = COPYING
var copied_tile: Tile
var copied_face: String


func get_tooltip_context():
 return {copy = state == COPYING, face = copied_face}


func _use():
 state = COPYING
 copied_tile = await get_selection()

 if copied_tile == null:
  _end_use()
  return

 copied_face = copied_tile.tile_face.get_face_text(false, false)
 copied_tile.animation.play("pressed")

 state = PASTING
 update_banner_label()

 var tile = await get_selection([copied_tile])

 if tile == null:
  _end_use()
  return

 apply_to_tile(tile, tile, false, false)
 copied_tile = null

 _post_use()


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.copy_statuses(copied_tile, copied_tile.get_face_statuses())
 tile.copy_face(copied_tile)

 if not is_preview:
  tile.animation.play("pressed")
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func is_tile_selectable(tile: Tile):
 if state == PASTING:
  return tile.faces.size() <= 1 and not tile.is_space()
 else:
  return tile.has_face() and tile.faces.size() == 1 and not tile.has_any_effect(Globals.FULL_WILDCARD_EFFECTS + [TileStatus.MYSTERY])


func has_special_tile_tooltip():
 return state == PASTING


func _end_use():
 state = COPYING
 super._end_use()
