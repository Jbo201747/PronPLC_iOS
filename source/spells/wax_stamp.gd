extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 transform_spell(SPELLS.WAX_LETTER_STAMP, true, true, false, false, false, func(spell: Spell): spell.face = tile.face)
 _post_use(false, true)


func is_tile_selectable(tile: Tile):
 return tile.has_face() and not tile.has_any_effect(Globals.WILDCARD_EFFECTS + [TileEffect.SHIMMERING])
