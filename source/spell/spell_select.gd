class_name SpellSelect extends MultiPanelMenu

signal completed

const SPELLS = Globals.SPELLS
const NUM_SPELLS: = 2


var spell_select_spell_scene: PackedScene = preload("res://source/spell/spell_select_spell.tscn")
var force_spell: Variant = null
var is_debug_select: = false
var select_completed: = false


var rng = {

 spell = RNG.new(), 

 curse = RNG.new(), 

 clown = RNG.new(), 
}


@onready var skip_button: MenuPanel = %SkipButton


func _ready() -> void :
 position = Vector2.ZERO
 super._ready()

 for i in NUM_SPELLS:
  var spell: SpellSelectSpell = spell_select_spell_scene.instantiate()
  add_child(spell)
  if i == 0:
   spell.set_left_tooltip()

  spell.selected.connect(_on_spell_selected)


func reseed(game_rng: RNG):
 RNG.reseed_rng_group(rng, game_rng)


func animate_title() -> void :
 Game.main.versus_label.text = StringManager.get_string("misc/spell_select_label")
 Game.main.versus_label.visible_characters = 0
 Game.main.versus_label.visible = true
 await Game.type_text_with_audio(Game.main.versus_label, 0.025)
 await Game.timeout(1.0)
 await Game.type_text_with_audio(Game.main.versus_label, 0.02, -1)
 Game.main.versus_label.visible = false


func animate_appear(instant: bool = false) -> void :
 if not Game.tile_board.is_slid_out:
  await Game.tile_board.slide_out(instant)
  await Game.conditional_timeout(0.16, instant)

 skip_button.start_appear()
 await super.animate_appear(instant)
 await Game.conditional_timeout(0.16, instant)
 animate_title()
 await Game.conditional_timeout(0.16, instant)
 await skip_button.appear()
 skip_button.finish_appear()



func animate_disappear(instant: bool = false) -> void :
 Game.main.versus_label.visible = false
 skip_button.disappear()
 await Game.conditional_timeout(0.08, instant)
 await super.animate_disappear(instant)
 await Game.conditional_timeout(0.16, instant)
 await AchievementManager.process_unlock_queue()
 await Game.tile_board.slide_in(instant)


func get_spells() -> Array[SpellSelectSpell]:
 var spells: Array[SpellSelectSpell] = []
 for child in get_children():
  if child is SpellSelectSpell:
   spells.append(child)

 return spells


func get_spell_select_panel(spell: Spell) -> SpellSelectSpell:
 for spell_select_spell in get_spells():
  if spell_select_spell.spell == spell:
   return spell_select_spell

 return null


func get_spell_index(spell: Spell) -> int:
 return get_spells().find(get_spell_select_panel(spell))


func get_spell_by_index(index: int) -> SpellSelectSpell:
 return get_spells()[index]


func generate_spells(act: int = -1, spell_select_index: int = -1):
 select_completed = false

 var clown_pool = Globals.GIFTS.duplicate()
 rng.clown.shuffle(clown_pool)

 var curses = Game.balance.curse_pool.duplicate()
 rng.curse.shuffle(curses)

 var select_panels: = get_spells()

 var exclude_spells: Array[String] = []
 var force_spells: Array[String] = []

 var force_spells_in_order: bool = false
 if force_spell != null:
  force_spells_in_order = true
  if force_spell is Array:
   force_spells.append_array(force_spell)
  else:
   force_spells.append(force_spell)
 elif Game.active_daily:
  force_spells.append_array(Game.active_daily.get_forced_spells(act, spell_select_index))
 else:
  var save: = SaveManager.get_save()
  if not save.data.seen_first_spell_select and Game.player.id != Globals.CHARACTERS.JUBILIST:
   force_spells = [SPELLS.FAKE_ID, SPELLS.SHIFT_CIPHER]
   save.data.seen_first_spell_select = true

 var selecting_spells: Array[Spell] = []
 for i in NUM_SPELLS:
  var spell_id: String = ""
  if force_spells_in_order and i < force_spells.size():
   spell_id = Game.main.pick_random_spell(exclude_spells, [force_spells[i]])
  else:
   var include_spells: Array = []
   if i == 0 and Game.player.id == Globals.CHARACTERS.CHILD and act == 0 and spell_select_index == 0:
    include_spells = Globals.DEFENSIVE_CHILD_SPELLS

   spell_id = Game.main.pick_random_spell(exclude_spells, force_spells, include_spells)

  var spell: Spell = null
  var was_forced: bool = spell_id in force_spells
  if Game.player.id == Globals.CHARACTERS.JUBILIST and spell_id != SPELLS.RED_LETTER and not was_forced:
   var gift: String = clown_pool.pop_front()
   spell = Spell.create(gift)
  else:
   spell = Spell.create(spell_id)

  exclude_spells.append(spell.id)

  var chosen_curse: String = ""
  if Game.balance.cursed_spell_chance > 0.0 and not was_forced:
   if rng.curse.randf() <= Game.balance.cursed_spell_chance:
    for curse in curses:
     if spell.spell_data.can_have_curse(curse):
      chosen_curse = curse
      curses.erase(curse)
      break

  if not was_forced and chosen_curse == Globals.SPELL_CURSES.CENSORED and spell.id not in Globals.GIFTS:
   if rng.curse.randf() <= 1.0 / 20.0:
    if Game.main.spell_in_pool(SPELLS.REPLACEMENT_CHARACTER):
     spell = Spell.create(SPELLS.REPLACEMENT_CHARACTER)

  if spell.id == SPELLS.RED_LETTER and Game.balance.cursed_starting_spells:
   chosen_curse = Globals.SPELL_CURSES.CURSED

  if chosen_curse != "":
   spell.set_curse(chosen_curse)

  selecting_spells.append(spell)

 if not force_spells_in_order:
  rng.spell.shuffle(selecting_spells)

 for i in NUM_SPELLS:
  var spell: = selecting_spells[i]
  spell._first_spawn()
  spell.charge = spell.max_charge
  select_panels[i].set_spell(spell)


func complete_spell_select() -> void :
 if select_completed:
  return

 select_completed = true

 var panels: = get_spells()
 for select_panel in panels:
  select_panel.selection_completed = true

 for select_panel in panels:
  var spell: = select_panel.spell
  spell.track_found()

  spell.just_added = false

  if not select_panel.visible:
   continue

  if spell.has_curse(Globals.SPELL_CURSES.CENSORED):
   select_panel.update(true)

  if spell.has_curse(Globals.SPELL_CURSES.NOSTALGIC):
   spell.shake.emit()
   Game.player.hurt(3, Globals.DamageType.DIRECT, false)
   await Game.player.recompose()

 completed.emit()
 request_close.emit()


func get_save_data() -> Dictionary:
 var save_data: Dictionary = {
  rng = RNG.get_rng_group_save(rng)
 }

 if active:
  var spell_saves: Array[Dictionary] = []
  for select_panel in get_spells():
   spell_saves.append(select_panel.spell.get_save_data())

  save_data.spells = spell_saves

 return save_data


func load_save_data(save: Dictionary):
 RNG.load_rng_group_save(rng, save.rng)

 if "spells" in save:
  var select_panels: = get_spells()

  for i in save.spells.size():
   var spell_save = save.spells[i]
   var spell: = Spell.create_from_save(spell_save)
   select_panels[i].set_spell(spell)


func _on_spell_selected() -> void :
 complete_spell_select()


func _on_skip_button_pressed() -> void :
 if not select_completed:
  Game.player.cancel_selection()
  complete_spell_select()
