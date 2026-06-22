@tool
class_name ChargeContainer extends Marker2D


var ChargeTileScene = preload("res://source/ui/spells/spell_charge_tile.tscn")


var spell: Spell
var charge_character: String:
 get():
  if Engine.is_editor_hint():
   return "e"
  elif spell.spell_data.has_charge_character():
   if spell.charge_character == "":
    return "?"
   else:
    return spell.charge_character
  else:
   return "*"
var max_charge: int:
 get():
  if Engine.is_editor_hint():
   return 4
  else:
   return spell.max_charge
var charge: int:
 get():
  if Engine.is_editor_hint():
   return 4
  else:
   return spell.charge


func _ready() -> void :
 if Engine.is_editor_hint():
  max_charge = 4
  update_max_charge(false)


func link_spell(_spell: Spell):
 spell = _spell
 spell.charge_container = self
 update_max_charge(false)


func unlink_spell() -> void :
 if spell == null:
  return
 elif not is_instance_valid(spell):
  spell = null
  return

 if spell.charge_container == self:
  spell.charge_container = null

 spell = null


func get_tiles() -> Array[SpellChargeTile]:
 var tiles: Array[SpellChargeTile] = []
 for child in get_children():
  if child is SpellChargeTile and not child.is_queued_for_deletion():
   tiles.append(child)

 return tiles


func update_max_charge(animate: = true) -> void :
 var tiles: = get_tiles()
 var existing_tiles = tiles.size()
 if existing_tiles < max_charge:
  for i in max_charge - existing_tiles:
   var charge_tile: SpellChargeTile = ChargeTileScene.instantiate()
   add_child(charge_tile)
   move_child(charge_tile, 0)
   tiles.push_front(charge_tile)
 elif existing_tiles > max_charge:
  for i in existing_tiles - max_charge:
   var charge_tile: SpellChargeTile = tiles.pop_back()
   if animate:
    charge_tile.remove()
   else:
    charge_tile.queue_free()

 update_charge_character(false)
 update_charge(false)

 var new_tiles: = tiles.size()
 var tile_spacing: = 12
 if new_tiles >= 6:
  tile_spacing = 8
 elif new_tiles == 5:
  tile_spacing = 10

 for i in new_tiles:
  var tile: = tiles[i]
  tile.position = Vector2( - tile_spacing * i, 0.0)


func update_charge_character(animate: = true) -> void :
 var tiles: = get_tiles()
 tiles.reverse()
 for tile in tiles:
  if animate:
   tile.reroll(charge_character)
   if tile != tiles[-1]:
    await Game.timeout(0.08)
  else:
   tile.set_face(charge_character)


func update_charge(animate: = true) -> void :
 var ordered_tiles: = get_tiles()
 ordered_tiles.reverse()

 var to_charge: Array[SpellChargeTile] = []
 var to_discharge: Array[SpellChargeTile] = []

 for i in ordered_tiles.size():
  var tile: = ordered_tiles[i]
  var should_be_charged: = i < charge
  if should_be_charged and not tile.charged:
   to_charge.append(tile)
  elif not should_be_charged and tile.charged:
   to_discharge.append(tile)

 if to_charge.size() > 0:
  await charge_tiles(to_charge, animate)

 if to_discharge.size() > 0:
  to_discharge.reverse()
  await discharge_tiles(to_discharge, animate)


func charge_tiles(tiles: Array[SpellChargeTile] = [], animate: = true):
 if tiles.size() == 0:
  tiles = get_tiles()
  tiles.reverse()

 for tile in tiles:
  if animate:
   if tile == tiles[-1]:
    await tile.charge()
   else:
    tile.charge()
    await Game.timeout(0.08)
  else:
   tile.set_charged(true)


func discharge_tiles(tiles: Array[SpellChargeTile] = [], animate: = true):
 if tiles.size() == 0:
  tiles = get_tiles()

 for tile in tiles:
  if animate:
   if tile == tiles[-1]:
    await tile.discharge()
   else:
    tile.discharge()
    await Game.timeout(0.08)
  else:
   tile.set_charged(false)


func pend_tile_animations() -> void :
 for tile in get_tiles():
  if tile.anim_player.is_playing():
   await tile.anim_player.animation_finished


func get_last_charge() -> SpellChargeTile:
 var ordered_tiles: = get_tiles()
 ordered_tiles.reverse()

 if charge > 0:
  var last_tile: = ordered_tiles[charge - 1]
  return last_tile
 else:
  return null


func stop_flashing() -> void :
 for tile in get_tiles():
  tile.stop_flashing()


func flash_last_charge(flash_anim: String) -> void :
 get_last_charge().flash(flash_anim)
