extends Spell


enum {
 FIND, 
 REPLACE_WITH
}

var state = FIND
var replacing_face = ""


func get_tooltip_context():
 return {find = state == FIND, face = replacing_face}


func _use():
 state = FIND
 var finding_tile = await get_selection()

 if finding_tile == null:
  _end_use()
  return

 replacing_face = finding_tile.face
 state = REPLACE_WITH
 update_banner_label()

 var replacing_with_tile = await get_selection()
 if replacing_with_tile == null or replacing_with_tile.face == replacing_face:
  _end_use()
  return

 for tile in get_tiles({face = replacing_face, exclude_effects = [TileEffect.SHIMMERING, TileStatus.MYSTERY]}):
  tile.copy_face(replacing_with_tile)

 _post_use()


func is_tile_selectable(tile):
 if not tile.has_face() or tile.is_shimmering() or tile.has_status(TileStatus.MYSTERY) or tile.has_effect(TileEffect.SLASHED):
  return false

 if state == REPLACE_WITH:
  return not tile.has_any_effect(Globals.FULL_WILDCARD_EFFECTS) and tile.face != replacing_face

 return true


func _end_use():
 state = FIND
 super._end_use()
