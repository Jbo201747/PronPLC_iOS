class_name Spell extends RefCounted


signal frame_updated
signal texture_updated
signal description_updated
signal charge_updated
signal curse_updated
signal shader_state_updated
signal animate_charge
signal stop_blinking
signal shake

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect

const MAX_CHARGE_LIMIT = 6
const FRAGILE_BREAK_CHANCE = 0.2

const SPELLS = Globals.SPELLS
const CURSE = Globals.SPELL_CURSES
const CHARGE_CATEGORIES = Globals.CHARGE_CATEGORIES
const FACE_EFFECT_PRIORITY = Globals.FACE_SPELL_EFFECT_PRIORITY
const STATUS_EFFECT_PRIORITY = Globals.STATUS_SPELL_EFFECT_PRIORITY
const AMBIVALENT_EFFECT_PRIORITY = Globals.AMBIVALENT_SPELL_EFFECT_PRIORITY
const NONPOSITIVE_EFFECT_PRIORITY = Globals.NONPOSITIVE_SPELL_EFFECT_PRIORITY

var max_charge = 1

var spell_data: SpellData
var id: String:
 get():
  return spell_data.id
var secret_id: String = ""

var charge_character = "":
 set(value):
  charge_character = value
  update_starve_limit()
var starve_limit = 99

var charge: int = 0:
 set(value):
  if value != charge:
   charge = value
   charge_updated.emit()
var extra_max_charge: int = 0

var turns_starved: int = 0
var tooltip_context = {}
var status_tooltips = []

var laced_temporarily_harmless: = false

var curse: String = ""

var rng = {
 spell = RNG.new(), 
 battle = RNG.new(), 
 turn = RNG.new(), 
 charge = RNG.new(), 
 tile = RNG.new(), 
 fragile = RNG.new(), 
 shiny = RNG.new(), 
 reroll = RNG.new(), 
}

var player_spell_slot: PlayerSpell = null
var charge_container: ChargeContainer = null
var has_process: = false
var has_process_select: = false
var is_ready: = false
var laced_deactivated: = false
var just_added: = false
var is_clay: = false:
 set(value):
  if is_clay != value:
   is_clay = value
   shader_state_updated.emit()

var main: = Game.main
var spell_container: = Game.spell_container
var player = Game.player
var tile_board: = Game.tile_board
var word_builder = Game.word_builder


static func create(_id: String, game_rng: RNG = Game.main.rng.game) -> Spell:
 var spell: = _instantiate_spell(_id)
 spell.reseed(game_rng)
 return spell


static func create_from_save(save: Dictionary) -> Spell:
 var spell: = _instantiate_spell(save.id)
 spell.load_save_data(save)
 return spell


static func _instantiate_spell(_id: String) -> Spell:
 var script: GDScript
 if _id in Globals.CUSTOM_SCRIPT_SPELLS:
  script = load("res://source/spells/" + Globals.CUSTOM_SCRIPT_SPELLS[_id] + ".gd")
 else:
  script = load("res://source/spells/" + _id + ".gd")

 return script.new(_id)


func _init(_id: String):
 spell_data = SpellData.new(_id)
 max_charge = spell_data.base_max_charge
 has_process = has_method("_process")
 has_process_select = has_method("_process_select")
 _spell_init()
 set_status_tooltips()


func reseed(game_rng):
 RNG.reseed_rng_group(rng, game_rng)



func _spell_init():
 pass



func set_status_tooltips():
 pass



func _first_spawn(is_transform: = false) -> void :
 if not has_curse(CURSE.ESOTERIC) or is_transform or Game.main.is_player_turn:
  randomize_charge()



func _gain() -> void :
 pass



func _ready() -> void :
 pass


func set_ready() -> void :
 if not is_ready:
  is_ready = true
  _ready()


func get_hv_frames() -> Vector2i:
 return Vector2i(1, 1)


func get_frame() -> int:
 return 0


func get_texture() -> Texture2D:
 if has_curse(CURSE.CURSED) and ResourceLoader.exists("res://arte/spells/" + id + "_cursed.png"):
  return ResourceLoader.load("res://arte/spells/" + id + "_cursed.png")
 elif ResourceLoader.exists("res://arte/spells/" + id + ".png"):
  return ResourceLoader.load("res://arte/spells/" + id + ".png")
 else:
  push_warning("Spell " + id + " does not have a sprite :(")
  return ResourceLoader.load("res://arte/spells/missing.png")


func randomize_charge(animate: = false):
 if spell_data.has_charge_character():
  var use_spell_data: SpellData = spell_data
  var update_max_charge: = false
  if spell_data.charge_category == CHARGE_CATEGORIES.RANDOM_SPELL:
   var use_spell_charge: String = rng.charge.pick_random(SpellData.random_charge_spells)
   use_spell_data = SpellData.new(use_spell_charge)
   max_charge = use_spell_data.base_max_charge + extra_max_charge
   update_max_charge = true

  var charge_pool = use_spell_data.get_charge_pool()
  var excluded_charges: = get_excluded_charges()
  if charge_character != "":
   excluded_charges.append(charge_character)

  for excluded_charge in excluded_charges:
   var exclude: PackedStringArray = [excluded_charge]
   if len(excluded_charge) > 1:
    exclude = excluded_charge.split()

   for exclude_char in exclude:
    charge_pool.erase(exclude_char)

  charge_character = rng.charge.pick_random(charge_pool)

  if charge_container != null:
   if update_max_charge:
    charge_container.update_max_charge(animate)
   else:
    await charge_container.update_charge_character(animate)


func get_excluded_charges() -> PackedStringArray:
 return []


func can_gain_max_charge():
 if spell_data.fixed_max_charge or not spell_data.has_charge():
  return false

 if max_charge >= MAX_CHARGE_LIMIT:
  return false

 return true


func is_owned():
 return player_spell_slot != null


func is_usable():
 return has_usable_charge()




func add_charge(amount, instant = false, animate_sprite: = true):
 var old_charge: = charge
 charge = clampi(charge + amount, 0, max_charge)
 turns_starved = 0
 if old_charge != charge and animate_sprite:
  animate_charge.emit()

 await charge_container.update_charge( not instant)


func pend_charging():
 await charge_container.pend_tile_animations()


func remove_charge(amount, instant = false):
 charge = clampi(charge - amount, 0, max_charge)
 await charge_container.update_charge( not instant)


func add_max_charge(amount: int = 1):
 amount = mini(amount, MAX_CHARGE_LIMIT - max_charge)
 if amount <= 0:
  return

 max_charge += amount
 extra_max_charge += amount
 charge_container.update_max_charge()


func remove_max_charge(amount: int = 1, remove_extra: = true):
 max_charge = maxi(0, max_charge - amount)
 if remove_extra:
  extra_max_charge = extra_max_charge - amount
 charge = min(charge, max_charge)
 charge_container.update_max_charge()


func has_usable_charge():
 if not spell_data.has_charge():
  return true

 return charge > 0


func is_fully_charged():
 return has_usable_charge() and charge == max_charge


func feed(tiles):
 if not spell_data.has_charge_character():
  return

 var amount = 0

 for tile in tiles:
  amount += get_tile_charge(tile)

 add_charge(amount)


func get_tile_charge(tile):
 var amount = 0
 for face in tile.tile_face.get_resolved_faces():
  for letter in face:
   if can_eat_letter(letter):
    amount += 1

 return amount


func can_eat_letter(letter):
 if (letter == charge_character or 
   (charge_character in Letters.NUMPAD_CHARACTERS and 
   letter in Letters.NUMPAD_CHARACTERS[charge_character])):
  return true

 return false


func get_selection(exclude_tiles = []) -> Tile:
 var condition = func(tile): return tile not in exclude_tiles and is_tile_selectable(tile)
 var selection = await player.get_selection(player.Selection.TILE, condition)

 if selection != null and not condition.call(selection):
  selection = handle_invalid_tile(selection)

 return selection


func cancel_selection():
 player.emit_signal("selected", null)
 _end_use()


func handle_invalid_tile(tile):
 tile.animation.play("shake")
 return null


func get_tiles(parameters = {}):
 parameters.rng = rng.tile
 return tile_board.get_tiles(parameters)


func get_label() -> String:
 var context = get_tooltip_context()
 return StringManager.get_string("spell/" + id + "/label", context)


func get_banner_label() -> String:
 var context = get_tooltip_context()
 if StringManager.has_string("spell/" + id + "/banner"):
  return StringManager.get_string("spell/" + id + "/banner", context)
 else:
  return StringManager.get_string("spell/modify_banner")


func update_banner_label():
 main.spell_banner.set_label(get_banner_label())


func get_title_context() -> Dictionary:
 var context = {
  spell_name = get_spell_name()
 }

 if curse != "" and curse != CURSE.CURSED and (curse != CURSE.CENSORED or id != SPELLS.REPLACEMENT_CHARACTER):
  context.curse_name = StringManager.get_string("curse/" + curse + "/name")

 return context


func get_title() -> String:
 return StringManager.get_string("spell/spell_title", get_title_context())


func get_spell_name() -> String:
 return StringManager.get_string("spell/" + id + "/name", get_tooltip_context())


func get_description() -> String:
 var context = get_tooltip_context()
 return StringManager.get_string("spell/" + id + "/description", context)


func get_curse_title() -> String:
 return StringManager.get_string("curse/" + curse + "/name")


func get_curse_description() -> String:
 return StringManager.get_string("curse/" + curse + "/description", {id = id})


func generate_player_spell_base_tooltip(tooltip: GameTooltip) -> void :
 tooltip.add_subtooltip(get_title(), get_description())


func generate_player_spell_tooltip(tooltip: GameTooltip) -> void :
 generate_player_spell_base_tooltip(tooltip)
 if is_cursed() and curse not in [CURSE.CENSORED, CURSE.NOSTALGIC, CURSE.SHINY]:
  if id == secret_id or secret_id not in Globals.GIFTS or not has_curse(CURSE.CURSED):
   add_curse_subtooltip(tooltip)

 add_status_subtooltips(tooltip)
 post_generate_tooltip(tooltip)


func generate_spell_select_tooltip(tooltip: GameTooltip) -> void :
 if is_cursed() and not has_curse(CURSE.CENSORED):
  add_curse_subtooltip(tooltip)
 add_status_subtooltips(tooltip)
 post_generate_tooltip(tooltip)


func has_spell_select_tooltip() -> bool:
 return not has_curse(CURSE.CENSORED) and (status_tooltips.size() > 0 or is_cursed())


func post_generate_tooltip(_tooltip):
 pass


func add_curse_subtooltip(tooltip) -> SubTooltip:
 var subtooltip = tooltip.add_subtooltip(get_curse_title(), get_curse_description())
 subtooltip.set_meta(&"custom_panel", "MenuPaperCurse")
 subtooltip.set_meta(&"custom_dotted_line", "MenuDottedLineCurse")
 subtooltip.set_title_color(Color(3381981183))
 return subtooltip


func add_status_subtooltips(tooltip):
 for status in status_tooltips:
  var status_name = status
  var status_context = {value = "X"}
  if status is Dictionary:
   status_name = status.status
   status_context = status.duplicate()
   status_context.erase("status")

  tooltip.add_subtooltip(
   StringManager.get_string("status/" + status_name + "/name", status_context), 
   StringManager.get_string("status/" + status_name + "/description", status_context), 
  )


func get_tooltip_context():
 return {id = id, curse = curse}


func _use():
 pass


func _post_use(use_charge = true, is_rerolling = false):
 laced_deactivated = true

 if main.spell_banner.is_active():
  main.spell_banner.slide_out()

 word_builder.resolve_words()

 AchievementManager.used_spell(self)
 main.run_stats.track_spell_used(id)
 if secret_id != "" and secret_id != id:
  main.run_stats.track_spell_used(secret_id)

 if use_charge and spell_data.has_charge():
  remove_charge(1)

 await tile_board.wait_for_idle()

 await tile_board.settle_board_if_state_changed()

 if main.is_player_turn and not word_builder.is_submitting:
  await tile_board.trigger_bottom_acid_tiles()

 await tile_board.wait_for_idle()

 if player.is_flinching:
  await player.recompose()

 if not is_rerolling and max_charge > 0:
  if spell_data.charge_category == CHARGE_CATEGORIES.LIMITED:
   await remove_max_charge(1)
  elif has_curse(CURSE.FRAGILE) and rng.fragile.randf() <= FRAGILE_BREAK_CHANCE:
   await remove_max_charge(1, false)

 if main.is_player_turn:
  await AchievementManager.process_unlock_queue()

 _end_use()


 if main.is_game_actionable(true, false, true):
  main.save_run()
 elif main.is_player_turn:
  push_warning("Game was inactionable after spell ", id, " use! ", main.player.is_using_spell(), " ", main.player.is_selecting(), " ", tile_board.idle, " ", word_builder.is_idle())


func _end_use():
 if main.spell_banner.is_active():
  main.spell_banner.slide_out()

 word_builder.resolve_words()
 player.set_active_spell(null)
 player.stopped_using_spell.emit()


func can_use_while_building():
 return not spell_data.removes_word


func is_active() -> bool:
 return player.active_spell == self


func start_using() -> void :
 if spell_data.immediate_effect:
  laced_deactivated = true

 player.set_active_spell(self)
 player.started_using_spell.emit()

 if not can_use_while_building():
  await word_builder.remove_tiles()
  await tile_board.wait_for_idle_tiles()

 await _use()


func battle_started():
 rng.turn.reseed(rng.battle)


func do_battle_start_transformation(exclude_spells):
 if secret_id in Globals.GIFTS or secret_id in Globals.MIRACLE_CACHES:
  reroll(exclude_spells)
 elif secret_id == SPELLS.CLOWN_CACHE:
  reroll(exclude_spells, true, true, false, false, true)


func battle_ended():
 pass


func do_battle_end_transformation():
 if secret_id == SPELLS.CLOWN_CACHE:
  transform_spell(secret_id, true, true, false, false, true)
 elif secret_id in Globals.GIFTS or secret_id in Globals.MIRACLE_CACHES:
  transform_spell(secret_id)
 elif has_curse(CURSE.ESOTERIC):
  charge_character = ""
  if charge_container != null:
   charge_container.update_charge_character(true)


func player_turn_started(is_battle_start: bool) -> void :
 laced_deactivated = false

 rng.spell.reseed(rng.turn)
 rng.tile.reseed(rng.turn)
 if secret_id in Globals.MIRACLE_CACHES and not is_battle_start:
  reroll()
  return

 if spell_data.charge_category == CHARGE_CATEGORIES.AUTO:
  await add_charge(max_charge)

 if has_curse(CURSE.ESOTERIC) and secret_id not in Globals.MIRACLE_CACHES and ( not is_battle_start or secret_id not in Globals.GIFT_SPELLS):
  await randomize_charge(true)


func get_laced_damage() -> int:
 if has_curse(CURSE.LACED) and has_usable_charge() and not laced_deactivated and not laced_temporarily_harmless:
  return 1
 else:
  return 0


func get_save_data():
 return {
  id = id, 
  charge = charge, 
  max_charge = max_charge, 
  extra_max_charge = extra_max_charge, 
  charge_character = charge_character, 
  curse = curse, 
  secret_id = secret_id, 
  laced_deactivated = laced_deactivated, 
  is_clay = is_clay, 
  rng = RNG.get_rng_group_save(rng), 
 }


func load_save_data(save):
 RNG.load_rng_group_save(rng, save.rng)
 charge = 0
 max_charge = save.max_charge
 extra_max_charge = save.extra_max_charge
 charge = save.charge
 charge_character = save.charge_character
 is_clay = save.get("is_clay", false)
 laced_deactivated = save.get("laced_deactivated", false)
 set_curse(save.curse)
 secret_id = save.secret_id


func get_binary_data() -> PackedByteArray:
 var simple_array: = SimpleByteArray.new()

 simple_array.store_string(curse)

 if is_clay:
  simple_array.store_u8(1)
 else:
  simple_array.store_u8(0)

 store_spell_binary_data(simple_array)

 return simple_array.byte_array


func store_spell_binary_data(_simple_array: SimpleByteArray) -> void :
 pass


func load_binary_data(data: PackedByteArray, data_version: int) -> void :
 var simple_array: = SimpleByteArray.new(data)

 if data_version > 3:
  curse = simple_array.get_string()
  if simple_array.invalid:
   curse = ""

 if data_version > 4:
  is_clay = simple_array.get_u8() == 1

 load_spell_binary_data(simple_array, data_version)


func load_spell_binary_data(_simple_array: SimpleByteArray, _data_version: int) -> void :
 pass


func has_curse(curse_id):
 return curse == curse_id


func is_cursed():
 return curse != ""


func set_curse(_curse):
 curse = _curse
 curse_updated.emit()
 texture_updated.emit()
 shader_state_updated.emit()


func update_starve_limit():
 for rarity in Globals.CHARGE_STARVE_LIMIT.keys():
  if charge_character in Globals.CHARGE_CHARACTERS[rarity]:
   starve_limit = Globals.CHARGE_STARVE_LIMIT[rarity]
   return


func turn_end():
 if not spell_data.has_charge_character() or charge_character not in Letters.ALPHABET:
  return

 if charge < max_charge and not tile_board.letter_exists(charge_character):
  turns_starved += 1
 else:
  turns_starved = 0


func is_starving():
 if charge_character not in Letters.ALPHABET:
  return false

 if charge == 0:
  return turns_starved >= starve_limit
 elif charge < max_charge:
  return turns_starved >= starve_limit + 1

 return false


func any_tile_selectable(tiles) -> bool:
 for tile in tiles:
  if is_tile_selectable(tile):
   return true

 return false



func is_tile_selectable(_tile):
 return true


func get_gift_reroll_pool(exclude_spells = [], allow_player_repeats: = false) -> Dictionary:
 var pool: Dictionary
 if secret_id == SPELLS.CLOWN_CACHE:
  pool = Globals.get_spell_pool()
  pool.erase(SPELLS.FUEL_RATION)
  pool.erase(SPELLS.RED_LETTER)
  pool.erase(SPELLS.CLOWN_CACHE)
 elif has_curse(CURSE.CURSED):
  pool = {}
  for category in Globals.SPELL_CATEGORIES:
   var category_pool = Globals.get_spell_pool(category)
   pool.merge(category_pool)
 else:
  var category: String = Globals.GIFT_TO_CATEGORY[secret_id]
  pool = Globals.get_spell_pool(category)

 if not allow_player_repeats:
  for spell in player.get_spells():
   pool.erase(spell.id)

 for spell_id in Globals.CLOWN_EXCLUDE + exclude_spells:
  pool.erase(spell_id)

 return pool


func reroll(exclude_spells = [], keep_secret_id = true, keep_curse = true, keep_charge = false, keep_charge_character = false, keep_extra_max_charge = false) -> Spell:
 var new_spell_id
 if secret_id in Globals.GIFT_SPELLS:
  var pool = get_gift_reroll_pool(exclude_spells)
  if pool.is_empty():
   pool = get_gift_reroll_pool([])
   if pool.is_empty():
    pool = get_gift_reroll_pool([], false)
    if pool.is_empty():
     pool = {SPELLS.REPLACEMENT_CHARACTER: 1.0}

  if is_cursed():
   for spell_id in pool.keys():
    var data = SpellData.new(spell_id)
    if not data.can_have_curse(curse):
     pool.erase(spell_id)

  new_spell_id = rng.reroll.weighted_random(pool)
 else:
  new_spell_id = main.pick_random_spell([SPELLS.RED_LETTER])

 return transform_spell(new_spell_id, keep_secret_id, keep_curse, keep_charge, keep_charge_character, keep_extra_max_charge)


func transform_spell(new_spell_id, keep_secret_id = true, keep_curse = true, keep_charge_amount = false, keep_charge_properties = false, keep_extra_max_charge = false, early_modifier: = Callable()) -> Spell:
 var new_spell: = _instantiate_spell(new_spell_id)
 new_spell.reseed(rng.reroll)

 if early_modifier.is_valid():
  early_modifier.call(new_spell)

 new_spell.laced_deactivated = laced_deactivated

 if keep_secret_id is bool:
  if keep_secret_id:
   new_spell.secret_id = secret_id
 else:
  new_spell.secret_id = keep_secret_id

 if keep_curse:
  new_spell.set_curse(curse)

 new_spell._first_spawn(true)

 if keep_charge_properties:
  new_spell.max_charge = max_charge
  new_spell.charge_character = charge_character

 if keep_extra_max_charge:
  extra_max_charge = max(0, extra_max_charge)
  if new_spell.can_gain_max_charge():
   new_spell.max_charge += extra_max_charge
  new_spell.extra_max_charge = extra_max_charge

 player_spell_slot.set_spell(new_spell)

 if keep_charge_amount:
  new_spell.add_charge(charge, false, false)
 else:
  new_spell.add_charge(99, false, false)

 new_spell.animate_charge.emit()

 return new_spell


func has_special_tile_tooltip() -> bool:
 return false



func spell_select(_spell_select_spell: SpellSelectSpell) -> bool:
 return false


func track_found() -> void :
 AchievementManager.found_spell(self)
