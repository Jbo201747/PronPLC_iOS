extends TileModifierSpell


var split_letters = {
 b = ["lo"], 
 d = ["cl"], 
 m = ["nn", "rn"], 
 w = ["vv"], 
 h = ["ln"], 
}


func _init():
 id = SPELLS.RAZOR_BLADE
 status_tooltips = [TileStatus.CRIT]


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 if is_preview:
  tile.set_face(split_letters[real_tile.face])
 else:
  var split_face = rng.spell.pick_random(split_letters[real_tile.face])
  tile.set_face(split_face)

 tile.add_status(TileStatus.CRIT)


func is_tile_selectable(tile):
 return tile.faces.size() == 1 and tile.face in split_letters.keys()
