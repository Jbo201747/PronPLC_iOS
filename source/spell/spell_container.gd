class_name SpellContainer extends Marker2D


const NUM_SPELLS = 4
const SPELL_SIZE = 93
const SPELL_PADDING = 4
const TOTAL_SPELL_SIZE = SPELL_SIZE * NUM_SPELLS + SPELL_PADDING * (NUM_SPELLS - 1)


var player_spell_scene: PackedScene = load("res://source/spell/player_spell.tscn")
var blank_spell_scene: PackedScene = load("res://source/ui/spells/blank_spell.tscn")

var spells_hidden: = false
var player_spells: Array[PlayerSpell] = []
var slots: Array[Node2D] = []
var blank_spells: Array[BlankSpell] = []


func get_spells() -> Array[Spell]:
 var spells: Array[Spell] = []
 for player_spell in player_spells:
  spells.append(player_spell.spell)

 return spells


func parent_spell(player_spell: PlayerSpell) -> void :
 if player_spell.get_parent() == null:
  add_child(player_spell)
 elif player_spell.get_parent() != self:
  player_spell.reparent(self)

 player_spell.despawned.connect(_on_spell_despawned.bind(player_spell))


func add_spell(spell: Spell) -> void :
 var player_spell: PlayerSpell = player_spell_scene.instantiate()
 parent_spell(player_spell)
 player_spell.set_spell(spell)
 player_spells.append(player_spell)
 position_spells()


func find_spell(spell: Spell) -> PlayerSpell:
 for player_spell in player_spells:
  if player_spell.spell == spell:
   return player_spell

 return null


func find_spell_index(spell: Spell) -> int:
 return player_spells.find(find_spell(spell))


func replace_spell(replace: Spell, replace_with: Spell) -> void :
 find_spell(replace).set_spell(replace_with)


func remove_spell(player_spell: PlayerSpell) -> void :
 var index: = player_spells.find(player_spell)
 if index != -1:
  player_spells.remove_at(index)
  position_spells()


func position_spells() -> void :
 slots.clear()

 var blanks: = blank_spells.duplicate()
 for blank in blanks:
  blank.visible = false

 for slot in NUM_SPELLS:
  if slot < player_spells.size():
   slots.append(player_spells[slot])
  else:
   if blanks.is_empty():
    var blank: BlankSpell = blank_spell_scene.instantiate()
    add_child(blank)
    blank_spells.append(blank)
    slots.append(blank)
   else:
    slots.append(blanks.pop_front())

 var spell_pos: = - floori(float(TOTAL_SPELL_SIZE) / 2)
 for slot in slots:
  if slot is BlankSpell:
   slot.visible = true
  elif slot is PlayerSpell:
   slot.update_glyph_action(player_spells.find(slot))

  slot.position = Vector2(spell_pos, 0.0)
  spell_pos += SPELL_SIZE + SPELL_PADDING


func hide_spells(instant: = false) -> void :
 if spells_hidden:
  return

 spells_hidden = true
 for slot in slots:
  if slot is PlayerSpell:
   if slot == slots[-1]:
    await slot.spell_paper.disappear(instant)
   else:
    slot.spell_paper.disappear(instant)
  elif slot is BlankSpell:
   if slot == slots[-1]:
    await slot.disappear(instant)
   else:
    slot.disappear(instant)

  if slot != slots[-1] and not instant:
   await Game.timeout(0.08)


func show_spells(instant: = false) -> void :
 if not spells_hidden:
  return

 spells_hidden = false
 for slot in slots:
  if slot is PlayerSpell:
   if slot == slots[-1]:
    await slot.spell_paper.appear(instant)
   else:
    slot.spell_paper.appear(instant)
  elif slot is BlankSpell:
   if slot == slots[-1]:
    await slot.appear(instant)
   else:
    slot.appear(instant)

  if slot != slots[-1] and not instant:
   await Game.timeout(0.08)


func _on_spell_despawned(player_spell: PlayerSpell) -> void :
 remove_spell(player_spell)


func get_save_data():
 var spell_saves = []
 for player_spell in player_spells:
  spell_saves.append(player_spell.spell.get_save_data())

 return spell_saves


func load_save_data(spell_saves):
 for spell_save in spell_saves:
  var spell: = Spell.create_from_save(spell_save)
  add_spell(spell)
