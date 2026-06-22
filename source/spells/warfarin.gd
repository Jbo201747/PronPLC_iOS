extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.BLEED]


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 if not is_tile_selectable(tile):
   tile.animation.play("shake")
   _end_use()
   return

 tile.randomize_face([], rng.spell)
 tile.add_status(TileStatus.BLEED)
 tile.add_poofcloud(Globals.COLORS.BLOOD)

 _post_use()


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and tile.has_face()
