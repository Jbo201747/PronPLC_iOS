extends TileModifierSpell


var do_randomization: = true
var face = "":
 set(value):
  face = value
  description_updated.emit()


func _spell_init():
 selectable_regions = [Selection.CENTER, Selection.LEFT_RIGHT]


func _first_spawn(is_transform: = false) -> void :
 if do_randomization:
  randomize_face()

 super._first_spawn(is_transform)


func get_excluded_charges() -> PackedStringArray:
 return [face]





func randomize_face():
 var other_charge_chars = []

 if rng.spell.randi_range(1, 100) <= 5:
  face = "*"
  return

 for spell in player.get_spells():
  if spell != self and spell.charge_character in Letters.ALPHABET:
   other_charge_chars.append(spell.charge_character)

 if other_charge_chars.is_empty() or rng.spell.randi_range(0, 1) == 0:
  face = rng.spell.pick_random(Letters.ALPHABET)
 else:
  face = rng.spell.pick_random(other_charge_chars)


func get_tooltip_context():
 return {face = face}


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 if selected_tile_region == TileRegion.CENTER or real_tile.face == " " or not can_extend_face(real_tile.face):
  tile.set_current_face(face)
 elif selected_tile_region == TileRegion.LEFT:
  tile.set_current_face(face + real_tile.face)
 elif selected_tile_region == TileRegion.RIGHT:
  tile.set_current_face(real_tile.face + face)

 if not is_preview:
  if id == SPELLS.ROTARY_DIAL:
   AudioManager.play_sound(Sounds.SPELLS.DIAL)
  else:
   AudioManager.play_sound(Sounds.SPELLS.STAMP)


func can_extend_face(tile_face) -> bool:
 return (3 - len(tile_face)) >= len(face)


func is_tile_selectable(tile: Tile):
 if tile.is_space() or tile.has_any_effect([TileEffect.SHIMMERING, TileEffect.SLASHED, TileStatus.MYSTERY]):
  return false

 if selected_tile_region == TileRegion.NONE:
  return true
 else:
  if selected_tile_region == TileRegion.CENTER:
   return tile.face != face
  else:
   return can_extend_face(tile.face)


func get_save_data():
 var save = super.get_save_data()
 save["face"] = face
 return save


func load_save_data(save):
 super.load_save_data(save)
 face = save.face
