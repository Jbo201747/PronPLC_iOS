class_name Player extends BattleUnit

signal recomposed

signal rerolled

signal selection_started
signal selection_finished
signal selected(selection)
signal selected_spell()

signal started_using_spell
signal stopped_using_spell

enum Selection{
 SPELL, 
 TILE
}

const CHARACTERS = Globals.CHARACTERS
const SPELLS = Globals.SPELLS
const SPELL_WIDTH_PADDING = 97

var active_selection_type = null
var active_selection_condition = null
var active_spell = null
var use_anvil_flinch: = false
var finishing_anvil_flinch: = false
var is_recomposing: = false
var starting_spells = []
var last_transformed_spells = []
var spell_container: SpellContainer = null


func _ready():
 if get_tree().current_scene == self:
  Game.start_run.call_deferred(id)
  return

 spell_container = Game.main.spell_container
 bruise_changed.connect(_on_bruise_changed)

 update_trans()
 Game.difficulty_changed.connect(update_trans)

 super._ready()


func _init_rng():
 rng.starvation = RNG.new()


func update_trans() -> void :
 if sprite is CharacterSprite:
  sprite.is_trans = is_trans()


func attack(enemy, damage):
 anim_player.play("attack")
 anim_player.queue("idle")
 await sprite.hit
 await deal_damage(enemy, damage)
 await pend_animation_stopped("attack")


func animate_flinch_lethal():
 if damage_received >= 99:
  sprite.blood_explode()
  sprite.hide()
  return

 if id in Sounds.CHARACTER_DEATH_SOUNDS:
  AudioManager.play_sound(Sounds.CHARACTER_DEATH_SOUNDS[id])

 if anim_player.has_animation("dying"):
  if "flinch" in anim_player.assigned_animation:
   anim_player.queue("dying")
   await anim_player.pend_animation_played("dying")
  else:
   anim_player.play("dying")

 await animate_death()


func battle_start():
 for spell in get_spells():
  spell.battle_started()

 await do_battle_start_transformations()


func do_battle_start_transformations():
 for spell in get_spells():
  spell.do_battle_start_transformation(last_transformed_spells)
  await Game.timeout(0.16)


func do_battle_end_transformations():
 last_transformed_spells = []
 for spell in get_spells():
  last_transformed_spells.append(spell.id)
  spell.do_battle_end_transformation()
  await Game.timeout(0.16)


func battle_end():
 for spell in get_spells():
  spell.battle_ended()

 await do_battle_end_transformations()


func turn_start(is_battle_start: bool):
 for spell in get_spells():
  spell.player_turn_started(is_battle_start)
  await Game.timeout(0.16)

 for spell in get_spells():
  await spell.pend_charging()

 turn_started.emit()


func end_turn():
 super.end_turn()

 var spells: = get_spells()

 var harming_spells: Array[Spell] = []
 var laced_damage: int = 0
 for spell in spells:
  var damage: = spell.get_laced_damage()
  if damage > 0:
   laced_damage += damage
   harming_spells.append(spell)

 if laced_damage > 0:
  for spell in harming_spells:
   spell.laced_deactivated = true
   spell.stop_blinking.emit()
   spell.shake.emit()
   await Game.timeout(0.08)

  harming_spells.clear()

  hurt(laced_damage, Globals.DamageType.DIRECT, false)
  Game.word_builder.remove_intent(Intent.LACED)
  if is_flinching:
   await recompose()

  await Game.timeout(Game.tile_board.TURN_END_STEP_DELAY)

 for spell in spells:
  await spell.turn_end()

 update_spell_hunger()


func get_spells() -> Array[Spell]:
 return spell_container.get_spells()


func get_num_spells():
 return get_spells().size()


func has_spell(spell):
 return spell in get_spells()


func has_red_letter_spell():
 for spell in get_spells():
  if spell.id in Globals.RED_LETTER_SPELLS or spell.secret_id in Globals.RED_LETTER_SPELLS:
   return true

 return false


func has_max_spells():
 return get_spells().size() >= spell_container.NUM_SPELLS


func take_lethal_damage():
 if main.is_player_turn:
  main.force_end_player_turn(false, false)


func update_spell_hunger():
 var starving_spells = []

 for spell in get_spells():
  if spell.is_starving():
   starving_spells.append(spell)

 if not starving_spells.is_empty():
  var spell = rng.starvation.pick_random(starving_spells)

  Game.tile_board.queue.queue_face(spell.charge_char)
  spell.turns_starved = 0


func set_active_spell(spell):
 active_spell = spell
 main.game_state_updated.emit()


func get_using_spell() -> Spell:
 if active_spell != null and active_spell.is_owned():
  return active_spell
 else:
  return null


func is_using_spell() -> bool:
 return get_using_spell() != null


func is_using_modifier_spell(only_with_regions: = false) -> bool:
 var using_spell: TileModifierSpell = get_using_spell() as TileModifierSpell
 if using_spell == null:
  return false

 if only_with_regions:
  return using_spell.get_selectable_tile_regions().size() > 1
 else:
  return true


func passes_selection_condition(object):
 if active_selection_condition == null:
  return true
 else:
  return active_selection_condition.call(object)


func get_selection(selection_type = Selection.TILE, condition = null):
 active_selection_type = selection_type
 active_selection_condition = condition

 main.game_state_updated.emit()

 if selection_type == Selection.TILE and condition != null:
  Tile.set_highlight_condition(condition)

 selection_started.emit()

 var selection = await selected

 active_selection_type = null
 if selection_type == Selection.TILE and condition != null:
  if Tile.highlight_condition == condition:
   Tile.clear_highlight_condition()

 main.game_state_updated.emit()
 selection_finished.emit()

 return selection


func cancel_selection():
 if active_selection_type != null:
  selected.emit(null)


func is_selecting(selection_type = null):
 if selection_type == null:
  return active_selection_type != null
 else:
  return active_selection_type == selection_type


func feint() -> void :
 is_flinching = true
 anim_player.play("feint")


func flinch(damage):
 var anim_suffix = ""
 is_flinching = true

 if not anim_player.has_animation("flinch_blocked"):
  anim_player.play("flinch")
  return

 if damage <= 0:
  anim_suffix = "_blocked"

 var do_anvil: bool = use_anvil_flinch and ( not finishing_anvil_flinch or not is_dead)
 if do_anvil:
  anim_suffix = anim_suffix + "_anvil"

 if do_anvil:
  if anim_player.current_animation == "flinch" + anim_suffix:
   anim_player.seek(0)
  else:
   anim_player.play("flinch" + anim_suffix)
 elif anim_player.assigned_animation in ["flinch", "flinch_blocked"]:
  anim_player.play("flinch_weak" + anim_suffix)

 elif anim_player.current_animation == "flinch_weak" + anim_suffix:
  anim_player.seek(0)

 elif "weak" in anim_player.assigned_animation:
  anim_player.play("flinch_weak" + anim_suffix)

 else:
  anim_player.play("flinch" + anim_suffix)


func recompose():
 if is_dead:
  if not is_dying:
   flinch_lethal(0)

  return

 if not anim_player.has_animation("recompose"):
  is_flinching = false
  return

 if is_recomposing:
  await recomposed
  return

 if not is_flinching:
  return

 is_recomposing = true
 if "flinch" in anim_player.assigned_animation and "anvil" in anim_player.assigned_animation:
  anim_player.queue("recompose_anvil")
  anim_player.queue("idle")
 elif "flinch" in anim_player.assigned_animation or "feint" in anim_player.assigned_animation:
  anim_player.queue("recompose")
  anim_player.queue("idle")

 await pend_animation_played("idle")

 is_recomposing = false
 recomposed.emit()
 is_flinching = false


func start_walking():
 if not anim_player.has_animation("walk"):
  return

 anim_player.play("start_walking")
 anim_player.queue("walk")


func stop_walking():
 if not anim_player.has_animation("walk"):
  return

 await sprite.pend_event("break")
 anim_player.play("halt")


func is_player():
 return true


func get_unit_name() -> String:
 return StringManager.get_string("character/" + id + "/title")


func is_trans():
 return Globals.is_character_trans(id, Game.difficulty)


func get_crit_chance() -> Dictionary:
 if id in Globals.CRIT_CHANCE:
  var crit_chance = Globals.CRIT_CHANCE[id].duplicate()
  crit_chance.merge(Globals.CRIT_CHANCE[CHARACTERS.LEXICOGRAPHER])
  return crit_chance
 else:
  return Globals.CRIT_CHANCE[CHARACTERS.LEXICOGRAPHER]


func has_natural_crit_chance() -> bool:
 var crit_chance = get_crit_chance()
 return crit_chance.BONUS_PER_LETTER > 0.0


func has_natural_crits() -> bool:
 var crit_chance = get_crit_chance()
 return not crit_chance.WILDCARD and crit_chance.BONUS_PER_LETTER > 0.0


func has_natural_wildcards() -> bool:
 var crit_chance = get_crit_chance()
 return crit_chance.WILDCARD and crit_chance.BONUS_PER_LETTER > 0.0


func crits_are_wildcards() -> bool:
 var crit_chance = get_crit_chance()
 return crit_chance.WILDCARD


func get_projectile_target() -> Vector2:
 if sprite.has_node("%ProjectileMarker"):
  var marker: Node2D = sprite.get_node("%ProjectileMarker")
  return marker.global_position
 else:
  printerr("Character is missing projectile marker!")
  return global_position + Vector2(0, -40)


func display_intent():
 if bruise > 0:
  add_intent(Intent.PLAYER_BRUISE, {bruise = bruise})


func _on_bruise_changed() -> void :
 update_intents()


func get_save_data():
 var save = super.get_save_data()
 save.last_transformed_spells = last_transformed_spells
 return save


func load_save_data(save):
 super.load_save_data(save)
 last_transformed_spells = save.get("last_transformed_spells", [])


func _on_sprite_event(event: String) -> void :
 super._on_sprite_event(event)
 if event == "step":
  if Game.main.act == 2:
   AudioManager.play_sound(Sounds.CHARACTER.STEP, 1.0, 1.0, &"SoundLowpassConst", self)
   AudioManager.play_sound(Sounds.CHARACTER.BLOCK, 1.0, 0.0, &"Sound", self)
  else:
   AudioManager.play_sound(Sounds.CHARACTER.STEP, 1.0, 1.0, &"Sound", self)
