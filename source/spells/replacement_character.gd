extends TileModifierSpell


const REPLACEMENT_GROUPS = [
 ["*", "♠", "♥", "♦", "♣"], 
 ["2", "3", "4", "5", "6", "7", "8", "9"], 
 ["/"], 
]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 if is_preview:
  tile.set_face("�")
 else:
  var group = rng.spell.pick_random(REPLACEMENT_GROUPS)
  var character = rng.spell.pick_random(group)
  if character == "/":
   tile.apply_slashed(rng.spell)
  else:
   tile.set_face(character)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func is_tile_selectable(tile: Tile):
 return tile.has_face() and not tile.has_any_effect(Globals.WILDCARD_EFFECTS + [TileEffect.SHIMMERING])
