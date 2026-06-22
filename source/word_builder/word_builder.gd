extends Node2D

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const Intent = Globals.Intent

const WARNINGS = {
 INVALID_WORD = "invalid_word", 
 REPEAT_WORD = "repeat_word", 
 PERIOD = "period", 
 CAPITAL = "capital", 
 STRAIGHT = "straight", 
 SHIMMERING = "shimmering", 
 LINKED = "linked", 
 MYSTERY = "mystery", 
}

const WARNING_PRIORITY = [WARNINGS.LINKED, WARNINGS.CAPITAL, WARNINGS.PERIOD, WARNINGS.STRAIGHT, WARNINGS.SHIMMERING, WARNINGS.MYSTERY, WARNINGS.REPEAT_WORD]

const SIMPLE_DAMAGE_INTENTS = [
 Intent.POISON, Intent.BLEED, Intent.CURSED, Intent.ACID, 
 Intent.BOMB, Intent.HAZE, Intent.ETERNAL
]

signal submitted_word(words: WordList, damage: int, turn_ending: bool)
signal updating_stats(words)
signal post_tile_stats(words)
signal finished_updating_stats(words)
signal state_updated
signal tiles_updated

var tiles: Array[Tile]:
 get():
  return word_holder.tiles
var invalidating_tiles = []

var words_list: = WordList.new()

var repeat_word: String = ""
var repeat_word_is_mystery: bool = false

var is_damaging: = false
var is_healing: = false
var damage: = 0
var defense: = 0
var laced_damage: = 0
var slot_damage: = 0

var slot_multipliers: Array = []:
 set(value):
  slot_multipliers = value
  word_holder.slot_multipliers = value
  if not slot_multipliers.is_empty():
   word_holder.max_tiles = slot_multipliers.size()
  else:
   word_holder.max_tiles = -1

var self_heal = 0
var bruise = 0
var tile_defense = 0
var damage_multiplier = 0
var defense_multiplier = 0
var is_submitting = false
var is_freezing = false
var intent_tiles = {}
var intent_value = {}

var player:
 get:
  return Game.player

@onready var new_word_indicator = %NewWord
@onready var word_hint: WordHint = %WordHint
@onready var intent_container = $IntentContainer
@onready var intent_high_position: Marker2D = %IntentHighPosition
@onready var word_holder: WordHolder = $WordHolder
@onready var main = Game.main
@onready var tile_board: = Game.tile_board

@onready var submit_button:
 get:
  return Game.main.submit_button


func _init() -> void :
 Game.word_builder = self


func _ready() -> void :
 main.game_state_updated.connect(update)


func can_add_tile(tile: Tile) -> bool:
 return word_holder.can_add_tile(tile)


func try_add_tile(tile: Tile, insert_at: int = -1) -> void :
 word_holder.try_add_tile(tile, insert_at)


func remove_tile(tile, should_update_stats = true, remove_tiles_after = true) -> void :
 await word_holder.remove_tile(tile, should_update_stats, remove_tiles_after)


func remove_tiles() -> void :
 await word_holder.remove_tiles()


func is_idle() -> bool:
 return not word_holder.is_removing and not is_submitting


func resolve_tile_words(use_tiles) -> WordList:
 var priority_words: = PackedStringArray()
 var depriority_words: = PackedStringArray()
 var priority_flag: WordDictionary.WordFlags = WordDictionary.WordFlags.NONE

 if Game.balance.no_repeat_words:
  depriority_words.append_array(main.run_stats.get_words())

 if Game.enemy != null:
  if Game.enemy.id == Enemies.HOUSEBROKEN:
   priority_words.append(Game.enemy.passcode)
  elif Game.enemy.id == Enemies.LUMP:
   if not Game.enemy.category_queue.is_empty():
    priority_flag = Globals.WORD_CATEGORY_FLAGS[Game.enemy.category_queue[0]]

 return WordUtility.resolve_tile_words(use_tiles, priority_words, depriority_words, priority_flag)


func resolve_words() -> void :
 words_list = resolve_tile_words(tiles)
 word_holder.words_list = words_list
 repeat_word = ""
 repeat_word_is_mystery = false
 if Game.balance.no_repeat_words:
  set_repeat_word()


func set_repeat_word() -> void :
 var mystery_repeat_word: String = ""
 for sub_list in words_list.sub_lists:
  var mystery_sub_list: = false
  for tile in sub_list.tiles:
   if tile.has_status(TileStatus.MYSTERY):
    mystery_sub_list = true
    break

  if mystery_sub_list:
   mystery_repeat_word = get_repeat_word(sub_list)
  else:
   var known_repeat_word: = get_repeat_word(sub_list)
   if known_repeat_word != "":
    repeat_word = known_repeat_word
    return

 if repeat_word == "" and mystery_repeat_word != "":
  repeat_word = mystery_repeat_word
  repeat_word_is_mystery = true


func get_repeat_word(word_list: WordList) -> String:
 var run_used_words: Array = main.run_stats.get_words()
 for word in word_list.words:
  if word in run_used_words:
   return word

 return ""


func get_words() -> WordList:
 return words_list


func can_submit_words(word_list: WordList) -> bool:
 return word_list.all_valid and word_list.words.size() > 0


func can_submit_tiles() -> bool:
 return invalidating_tiles.is_empty()


func can_submit() -> bool:
 var words = get_words()
 return can_submit_tiles() and can_submit_words(words) and repeat_word == ""


func add_intent(intent, context = null, for_tiles = null) -> void :
 if for_tiles == null:
  for_tiles = intent_tiles.get(intent)

 intent_container.update_intent(intent, context, for_tiles, true)


func get_tile_multiplier(tile: Tile) -> int:
 var slot_data: Variant = get_tile_slot_data(tile)
 if slot_data == null or slot_data is not int or slot_data == -99:
  return 1
 else:
  return slot_data


func get_tile_slot_data(tile: Tile) -> Variant:
 var tile_index: = tiles.find(tile)
 if tile_index == -1 or tile_index >= slot_multipliers.size():
  return null
 else:
  return slot_multipliers[tile_index]


func add_intent_tile(intent: Intent, tile: Tile, value: int = 0) -> void :
 intent_tiles.get_or_add(intent, []).append(tile)
 if intent in intent_value:
  intent_value[intent] += value
 else:
  intent_value[intent] = value


func remove_intent(intent: Intent) -> void :
 intent_container.remove_intents([intent])


func add_warning(warnings: Dictionary, warning_id: String, context: Dictionary = {}) -> void :
 warnings[warning_id] = context


func add_warning_tile(warnings: Dictionary, warning_id: String, tile: Tile) -> void :
 invalidating_tiles.append(tile)
 if warning_id not in warnings:
  warnings[warning_id] = {}


func reset_stats() -> void :
 damage = 0
 defense = 0
 self_heal = 0
 bruise = 0
 tile_defense = 0
 damage_multiplier = 1
 defense_multiplier = 1
 laced_damage = 0
 slot_damage = 0


func update_stats() -> void :
 var words: = get_words()
 intent_container.reset_intents()

 reset_stats()

 updating_stats.emit(words)

 intent_tiles = {}
 intent_value = {}

 invalidating_tiles = []

 var warnings: Dictionary = {}

 var shimmering_tiles = []
 var link_color_tiles = {}
 for tile: Tile in tiles:
  var value: = tile.get_value()
  var frozen: = tile.has_status(TileStatus.FROZEN)

  if tile.has_value():
   if tile.type == TileType.DAMAGE or frozen:
    add_intent_tile(Intent.DAMAGE, tile)
    damage += value

   if tile.type == TileType.DEFENSE or frozen:
    add_intent_tile(Intent.DEFENSE, tile)
    defense += value

   if tile.has_status(TileStatus.CANDY):
    add_intent_tile(Intent.HEAL, tile)
    self_heal += value

   var slot_data: Variant = get_tile_slot_data(tile)
   if slot_data == -99:
    add_intent_tile(Intent.SPIKED_SLOTS, tile)
    slot_damage += value

  var is_crit: = tile.has_status(TileStatus.CRIT)
  var bomb_status = tile.get_status(TileStatus.BOMB)
  if bomb_status:
   is_crit = bomb_status.turns == 1

  if is_crit:
   var crit_addition: float = Game.balance.crit_value - 1
   if tile.type == TileType.DAMAGE:
    add_intent_tile(Intent.DAMAGE_MULTIPLIER, tile)
    damage_multiplier += crit_addition
   else:
    add_intent_tile(Intent.DEFENSE_MULTIPLIER, tile)
    defense_multiplier += crit_addition

  if tile.is_shimmering():
   shimmering_tiles.append(tile)

  var bruise_status: = tile.get_status(TileStatus.BRUISE)
  if bruise_status:
   add_intent_tile(Intent.BRUISE, tile)
   var status_value = max(value, 1) + Game.balance.status_added_value
   bruise += status_value

  var period: = tile.get_status(TileStatus.PERIOD)
  if period and period.invalidates_word():
   add_warning_tile(warnings, WARNINGS.PERIOD, tile)

  var capital: = tile.get_status(TileStatus.CAPITAL)
  if capital and capital.invalidates_word():
   add_warning_tile(warnings, WARNINGS.CAPITAL, tile)

  var linked: = tile.get_status(TileStatus.LINKED)
  if linked:
   link_color_tiles.get_or_add(linked.link_id, []).append(tile)

  var gay: = tile.get_status(TileStatus.GAY)
  if gay and gay.invalidates_word():
   add_warning_tile(warnings, WARNINGS.STRAIGHT, tile)

 var invalidated_linked_count: int = 0
 var invalidated_linked_colors = {}
 var board_tiles = tile_board.get_tiles({sorted = true, in_word = false})
 for tile: Tile in board_tiles:
  var linked: = tile.get_status(TileStatus.LINKED)
  if linked and linked.link_id in link_color_tiles:
   invalidated_linked_count += 1
   invalidated_linked_colors[linked.link_id] = true
   link_color_tiles[linked.link_id].append(tile)

  if tile.has_status(TileStatus.DEFAULT):
   continue

  var poison: = tile.get_status(TileStatus.POISON)
  if poison:
   add_intent_tile(Intent.POISON, tile, poison.get_status_value())

  var bleed: = tile.get_status(TileStatus.BLEED)
  if bleed:
   add_intent_tile(Intent.BLEED, tile, Game.balance.bleed_damage)

  var cursed: = tile.get_status(TileStatus.CURSED)
  if cursed:
   add_intent_tile(Intent.CURSED, tile, cursed.get_status_value())

  var eternal: = tile.get_status(TileStatus.ETERNAL)
  if eternal and not eternal.played_this_turn:
   add_intent_tile(Intent.ETERNAL, tile, eternal.get_status_value())

  var acid: = tile.get_status(TileStatus.ACID)
  if acid and acid.will_fall_on_turn_end():
   add_intent_tile(Intent.ACID, tile, acid.get_status_value())

  var bomb: = tile.get_status(TileStatus.BOMB)
  if bomb and bomb.will_explode_on_turn_end():
   add_intent_tile(Intent.BOMB, tile, bomb.get_status_value())

  var haze: = tile.get_status(TileStatus.HAZE)
  if haze:
   add_intent_tile(Intent.HAZE, tile, Game.balance.bleed_damage)

 tile_defense = int(ceil(defense * defense_multiplier))

 post_tile_stats.emit(words)

 damage = int(ceil(damage * damage_multiplier))
 defense = int(ceil(defense * defense_multiplier))

 is_damaging = damage != 0 or Intent.DAMAGE in intent_tiles
 is_healing = self_heal != 0 or Intent.HEAL in intent_tiles

 if is_damaging:
  add_intent(Intent.DAMAGE, {damage = damage})

 if defense != 0 or Intent.DEFENSE in intent_tiles:
  add_intent(Intent.DEFENSE, {defense = defense})

 if is_healing:
  add_intent(Intent.HEAL, {heal = self_heal})

 if bruise > 0:
  add_intent(Intent.BRUISE, {damage = bruise})

 if slot_damage > 0:
  add_intent(Intent.SPIKED_SLOTS, {damage = slot_damage})

 if damage_multiplier > 1:
  add_intent(Intent.DAMAGE_MULTIPLIER, {multiplier = damage_multiplier})

 if defense_multiplier > 1:
  add_intent(Intent.DEFENSE_MULTIPLIER, {multiplier = defense_multiplier})

 for spell in player.get_spells():
  var spell_damage: int = spell.get_laced_damage()
  if spell_damage > 0:
   laced_damage += spell_damage

 if laced_damage > 0:
  add_intent(Intent.LACED, {damage = laced_damage})

 for intent in SIMPLE_DAMAGE_INTENTS:
  if intent in intent_tiles:
   add_intent(intent, {damage = intent_value[intent]})

 var invalid_link_tiles = []
 var invalid_link_colors = []
 for color in invalidated_linked_colors:
  invalid_link_colors.append(StringManager.get_string("misc/linked_color/" + color))
  for tile in link_color_tiles[color]:
   invalid_link_tiles.append(tile)

 if invalid_link_tiles.size() > 0:
  add_warning(warnings, WARNINGS.LINKED, {invalid_linked = invalidated_linked_count})
  invalidating_tiles.append_array(invalid_link_tiles)

 if repeat_word != "":
  if repeat_word_is_mystery:
   add_warning(warnings, WARNINGS.REPEAT_WORD)
  else:
   add_warning(warnings, WARNINGS.REPEAT_WORD, {word = repeat_word})

 if not words.all_valid and tiles.size() > 0:
  for sub_list in words.sub_lists:
   var has_invalid_mystery: = false
   if not sub_list.all_valid:
    for tile in sub_list.tiles:
     if tile.has_status(TileStatus.MYSTERY):
      has_invalid_mystery = true
      break

   if has_invalid_mystery:
    add_warning(warnings, WARNINGS.MYSTERY)
    break


 var has_warning: = false
 for warning_id in WARNING_PRIORITY:
  if warning_id in warnings:
   has_warning = true
   word_hint.set_warning("misc/word_warnings/" + warning_id, warnings[warning_id])
   break

 if not has_warning:
  word_hint.reset_warning()

 if words.maximum_length > 0 and SaveManager.get_show_crit_chance_enabled():
  if tile_board.crit_chance > 0:
   var player_crit_chance = player.get_crit_chance()
   var crit_bonus = tile_board.calculate_crit_bonus(words.sub_lists)
   var next_chance = tile_board.calculate_added_crit_chance(crit_bonus)
   var is_wildcard: bool = player.crits_are_wildcards()
   var context = {
    chance = "%.1f" % [next_chance * 100.0], 
    bonus = "%.1f" % [player_crit_chance.BONUS_PER_LETTER * 100.0], 
    truncated_chance = "%.0f" % [next_chance * 100.0], 
    natural = player.has_natural_crit_chance(), 
    wildcard = is_wildcard, 
   }
   if is_wildcard:
    context.name_override = "wildcard_chance"

   add_intent(Intent.CRIT_CHANCE, context)

 finished_updating_stats.emit(words)
 intent_container.update_intents(false, true)


func update():
 if is_idle() and main.is_player_turn:
  update_stats()

 var submittable = can_submit()
 if not is_submitting:
  word_holder.waving = submittable
  word_holder.wave_scale = max(tiles.size(), 3) / 20.0

  for tile in tiles:
   if tile in invalidating_tiles:
    if tile.animation.current_animation != "jitter" and not tile.animation.get_queue().has("jitter"):
     tile.animation.queue("jitter")
   elif tile.animation.current_animation == "jitter" or tile.animation.get_queue().has("jitter"):
    tile.animation.clear_queue()
    tile.animation.play("RESET")


func on_tile_cleared(tile: Tile, spells: Array[Spell]) -> void :
 for spell in spells:
  spell.feed([tile])


func clear_word(charges_spells: = true):
 var spells = player.get_spells()
 if charges_spells:
  await word_holder.clear_tiles(on_tile_cleared.bind(spells))
 else:
  await word_holder.clear_tiles(Callable())


func confirm_word(do_end_turn: = true, do_charge_spells: = true):
 var words = get_words()
 var enemy = main.enemy

 word_hint.reset_warning()

 is_submitting = true
 main.game_state_updated.emit()
 submitted_word.emit(words, damage, do_end_turn)

 if is_freezing:
  return

 AudioManager.play_sound(Sounds.UI.WORD_SUBMIT)

 var save: = SaveManager.get_save()
 var new_word: = false
 var new_word_is_slur: = false
 for word in words.words:
  if word not in save.word_stats:
   new_word = true
   if WordUtility.dictionary.word_has_flag(word, WordDictionary.WordFlags.SLUR):
    new_word_is_slur = true

 AchievementManager.submitted_words(words, tiles, damage, defense, self_heal, tile_defense)

 intent_container.keep_intents(SIMPLE_DAMAGE_INTENTS + [Intent.LACED, Intent.SPIKED_SLOTS])

 tile_board.add_crit_bonus(words.sub_lists)

 var harming_laced_spells: Array[Spell] = []
 for spell: Spell in player.get_spells():
  spell.laced_temporarily_harmless = false
  if spell.get_laced_damage() > 0:
   harming_laced_spells.append(spell)
  else:
   spell.laced_temporarily_harmless = true

 await clear_word(do_charge_spells)

 if new_word and save.word_stats.size() >= Globals.QOL_ADJUSTMENT_COUNT:
  new_word_indicator.set_text(new_word_is_slur)
  new_word_indicator.new_word()

 await tile_board.fill_board()
 await tile_board.wait_for_idle()

 if player.is_flinching:
  await player.recompose()

 player.defense += defense

 if bruise < 0:
  player.defense += abs(bruise)
 else:
  player.bruise += bruise

 if self_heal >= 0 and is_healing:
  player.heal(self_heal, true)
 elif self_heal < 0:
  player.hurt( - self_heal, Globals.DamageType.PIERCING)

 if slot_damage > 0:
  player.hurt(slot_damage)
  remove_intent(Intent.SPIKED_SLOTS)

 if player.is_flinching:
  await player.recompose()

 if (damage != 0 or is_damaging) and not player.is_defeated:
  await player.attack(enemy, damage)

 main.run_stats.submitted_words(words, damage)

 var turn_will_end: bool = do_end_turn or player.is_defeated or enemy.is_defeated or enemy.triggering_player_turn_end
 if turn_will_end and not do_end_turn:
  await main.start_ending_player_turn(true)

 for spell: Spell in player.get_spells():
  if spell not in harming_laced_spells and turn_will_end:
   spell.laced_deactivated = true

  spell.laced_temporarily_harmless = false

 if not turn_will_end:
  await tile_board.trigger_bottom_acid_tiles()

  if player.is_flinching:
   await player.recompose()

 is_submitting = false

 reset_stats()
 resolve_words()
 main.game_state_updated.emit()

 if enemy != null and enemy.is_flinching:
  await enemy.stopped_flinching

 if turn_will_end:
  enemy.triggering_player_turn_end = false
  end_turn()


func submit_word() -> void :
 is_submitting = true
 await main.start_ending_player_turn(true)
 await confirm_word()


func submit_without_ending_turn(charge_spells: = true) -> void :
 Game.pause_turn_timers.emit()
 await confirm_word(false, charge_spells)

 if Game.main.is_player_turn:
  if slot_multipliers.size() != 0:
   await word_holder.show_slots()

  Game.resume_turn_timers.emit()


func on_player_turn_ending() -> void :
 if not is_submitting:
  intent_container.keep_intents(SIMPLE_DAMAGE_INTENTS + [Intent.LACED, Intent.SPIKED_SLOTS])
  await word_holder.hide_slots()


func _on_submit_button_pressed():
 if submit_button.state == submit_button.PENDING:
  if tiles.size() > 0:
   var invalid_word: String = ""
   var mystery_invalid_word: String = ""
   for sub_list in words_list.sub_lists:
    if sub_list.invalid_word == "":
     continue

    var has_mystery_tile: bool = false
    for tile in sub_list.tiles:
     if tile.has_status(TileStatus.MYSTERY):
      has_mystery_tile = true
      break

    if has_mystery_tile:
     mystery_invalid_word = sub_list.invalid_word
    else:
     invalid_word = sub_list.invalid_word

   if invalid_word != "":
    word_hint.temporary_warning("misc/word_warnings/invalid_word", {word = invalid_word})
   elif mystery_invalid_word != "":
    word_hint.temporary_warning("misc/word_warnings/invalid_word", {})
 elif submit_button.state == submit_button.REROLL:
  InputManager.vibrate(0.5, 0.1, 0.15)
  await main.start_ending_player_turn()
  end_turn(true)
  return
 elif submit_button.state == submit_button.REROLL_INITIAL:
  Game.main.game_state_updated.emit()
 else:
  InputManager.vibrate(0.3, 0.0, 0.2)
  submit_word()


func end_turn(reroll = false):
 if reroll:
  player.rerolled.emit()
 else:
  player.action_finished.emit()


func _on_word_holder_updated() -> void :
 main.game_state_updated.emit()


func _on_word_holder_updated_tiles() -> void :
 resolve_words()
 main.game_state_updated.emit()
 tiles_updated.emit()
