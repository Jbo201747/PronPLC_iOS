extends Node

signal exiting_game
signal exit_blocker_removed
signal taking_screenshot
signal difficulty_changed
signal main_scene_loaded
signal main_scene_unloaded

signal start_turn_timers
signal stop_turn_timers
signal pause_turn_timers
signal resume_turn_timers

signal tile_selected
signal tile_deselected

var main: Main = null
var main_menu: MainMenu = null
var word_builder = null
var tile_board: TileBoard = null
var player = null
var spell_container: SpellContainer = null
var enemy = null
var debug_spawn_enemy: String = ""
var debug_spawn_spells: Array[String] = []
var debug_force_words: Array[String] = []
var debug_enemy_health: int = -1
var debug_player_health: int = -1
var debug_character_select: = false
var debug_print_achievement_unlocks: = false
var new_run_character = Globals.CHARACTERS.LEXICOGRAPHER
var new_run_seed = null
var active_daily: Daily = null
var debug_run: = false
var is_seeded = false
var running_from_menu = false
var exiting_to_menu = false
var loading_run_save = null
var constant_timeout_start: int = -1
var difficulty = 0

var exit_blockers: Array[String] = []
var quitting: = false

var difficulty_balance: Dictionary = {
 enemy_difficulty = {
  0: 0, 
  1: 1, 
  5: 2, 
  10: 3, 
 }, 
 enemy_health = {
  0: 0, 
  1: 1, 
  6: 2, 
  10: 3, 
 }, 
 cursed_spell_chance = {
  0: 0.0, 
  2: 1.0 / 3.0, 
  7: 2.0 / 3.0, 
  10: 1.0, 
 }, 
 curse_pool = {
  0: [], 
  2: Globals.VIOLET_CURSES, 
  7: Globals.VIOLET_CURSES + Globals.ORANGE_CURSES, 
 }, 
 capital_period_chance = {
  0: 0.0, 
  3: 0.025, 
 }, 
 capital_period_chance_fishing = {
  0: 0.0, 
  3: 0.03, 
 }, 
 bigram_chance = {
  0: 0.0, 
  3: 0.05, 
  10: 0.075, 
 }, 
 bigram_chance_fishing = {
  0: 0.0, 
  3: 0.08, 
 }, 
 bigram_become_trigram_chance = {
  0: 0.0, 
  10: 0.25, 
 }, 
 no_repeat_words = {
  0: false, 
  4: true, 
 }, 

 boss_healing = {
  0: 10, 
  8: 5, 
 }, 
 boss_healing_child = {
  0: 6, 
  8: 3, 
 }, 


 bleed_damage = {
  0: 1, 
  9: 2
 }, 
 coal_turns = {
  0: 1, 
  9: 2
 }, 
 linked_turns = {
  0: 1, 
  9: 2, 
 }, 
 status_added_value = {
  0: 0, 
  9: 1, 
 }, 
 bomb_multiplier = {
  0: 2, 
  9: 3, 
 }, 
 mystery_options = {
  0: 5, 
  9: 7
 }, 
 haze_time = {
  0: 15, 
  9: 10, 
 }, 


 defense_in_bag = {
  0: 5, 
  10: 4, 
 }, 
 damage_in_bag = {
  0: 27, 
 }, 
 reroll_defense = {
  0: 3, 
  10: 0, 
 }, 
 cursed_starting_spells = {
  0: false, 
  10: true, 
 }, 

 defense_fish_chance = {
  0: 0.2, 
  10: 0.2 * 0.8, 
 }, 
 damage_crit_fish_chance = 1.0 / 15.0, 
 defense_crit_fish_chance = 0.1, 
 evil_fish_chance = {
  0: 0.0, 
  10: 1.0 / 12.5, 
 }, 


 crit_value = 1.5, 
 screw_turns = 1, 
}

var balance = null


var random = RNG.new()

var debug_painting_status = null


func _ready() -> void :
 get_tree().auto_accept_quit = false

 StringManager.set_data_source("global", {
  steam_inactive = is_steam_inactive
 })


func _notification(what: int) -> void :
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  quit(true)


func is_steam_inactive() -> bool:
 return not OS.has_feature("steamless") and not Bridge.steam_initialized


func add_exit_blocker(id: String) -> void :
 if id not in exit_blockers:
  exit_blockers.append(id)


func remove_exit_blocker(id: String) -> void :
 if id in exit_blockers:
  exit_blockers.erase(id)
  exit_blocker_removed.emit()


func scale_difficulty(dictionary: Dictionary, difficulty_index: int) -> Variant:
 var only_int_keys: = true
 for key in dictionary:
  if key is not int:
   only_int_keys = false
   break

 if only_int_keys:
  for i in range(difficulty_index, -1, -1):
   if i in dictionary:
    return dictionary[i]

  push_error("Missing a key for difficulty 0")
 else:
  var out_dictionary: Dictionary = {}
  for key in dictionary:
   if dictionary[key] is Dictionary:
    out_dictionary[key] = scale_difficulty(dictionary[key], difficulty_index)
   else:
    out_dictionary[key] = Util.copy(dictionary[key])

  return out_dictionary

 return {}


func update_balance_vars():
 balance = scale_difficulty(difficulty_balance, Game.difficulty)
 StringManager.set_data_source("balance", balance)


func release_node_handles():
 main = null
 word_builder = null
 tile_board = null
 player = null
 spell_container = null
 enemy = null


func is_in_run():
 return is_instance_valid(get_tree().current_scene) and get_tree().current_scene.name == "Main"


func start_run(run_character, run_seed = null, debug: = false):
 DailyManager.set_process(false)
 AudioManager.fade_music()
 AudioManager.fade_sounds()
 debug_run = debug
 new_run_character = run_character
 new_run_seed = run_seed
 active_daily = null
 is_seeded = run_seed != null
 loading_run_save = null
 get_tree().change_scene_to_file("res://source/main.tscn")


func start_daily_run(debug: = false) -> void :
 DailyManager.set_process(false)
 AudioManager.fade_music()
 AudioManager.fade_sounds()
 debug_run = debug
 active_daily = DailyManager.current_daily
 difficulty = active_daily.difficulty
 new_run_character = active_daily.character
 new_run_seed = active_daily.game_seed
 is_seeded = true
 loading_run_save = null
 get_tree().change_scene_to_file("res://source/main.tscn")


func load_run(run_save):
 DailyManager.set_process(false)
 AudioManager.fade_music()
 AudioManager.fade_sounds()
 loading_run_save = run_save
 get_tree().change_scene_to_file("res://source/main.tscn")


func return_to_menu():
 DailyManager.set_process(true)
 AudioManager.fade_music()
 AudioManager.fade_sounds()
 get_tree().change_scene_to_file("res://source/main_menu.tscn")


func timeout(duration: float) -> void :
 await get_tree().create_timer(duration).timeout


func conditional_timeout(duration: float, skip: bool = false) -> void :
 if not skip:
  await timeout(duration)


func cancelable_timeout(duration: float, skip: bool = false) -> CancelableTimeout:
 if skip:
  return null

 return CancelableTimeout.new(get_tree(), duration)


func start_constant_timeout():
 constant_timeout_start = Time.get_ticks_msec()


func constant_timeout(duration: float):
 var constant_timeout_end = Time.get_ticks_msec()
 var already_timed_seconds = float(constant_timeout_end - constant_timeout_start) / 100.0
 var remaining_duration = duration - already_timed_seconds
 if remaining_duration > 0.0:
  await timeout(remaining_duration)


func quit(from_notification: = false):
 if not quitting:
  quitting = true
  if not from_notification:
   get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

  exiting_game.emit()
  while not exit_blockers.is_empty():
   await exit_blocker_removed

  get_tree().quit()


func screenshake(intensity: float, falloff_duration: float, sustain_duration: float = 0.0, no_randomize: = false):
 get_shake_camera().shake(intensity, falloff_duration, sustain_duration, no_randomize)


func menu_shake(light: = false) -> void :
 if SaveManager.get_menu_shake_setting():
  if light:
   screenshake(1, 0.24, 0.0, true)
  else:
   screenshake(2, 0.32, 0.0, true)


func _play_type_text_sound(_playback: Util.TypeTextPlayback) -> void :
 AudioManager.play_sound(Sounds.UI.TEXT_TYPING)


func type_text_with_audio(label: Control, delay: float = 0.08, rate: int = 1, num_characters: int = -1) -> void :
 await Util.type_text(label, delay, rate, num_characters, _play_type_text_sound)


func type_text_with_audio_cancelable(label: Control, delay: float = 0.08, rate: int = 1, num_characters: int = -1, complete_on_cancel: bool = false, control_string: String = "") -> Util.TypeTextPlayback:
 return Util.type_text_cancelable(label, delay, rate, num_characters, _play_type_text_sound, complete_on_cancel, control_string)


func get_shake_camera() -> ShakeCamera:
 var current_scene = get_tree().current_scene
 if current_scene.has_node("%ShakeCamera"):
  return current_scene.get_node("%ShakeCamera")
 else:
  return null


func get_shadow_group():
 var current_scene = get_tree().current_scene
 if current_scene.has_node("%ShadowGroup"):
  return current_scene.get_node("%ShadowGroup")
 else:
  return null


func get_particle_target(from_node: Node):
 var particle_targets = get_tree().get_nodes_in_group("particle_target")
 particle_targets.reverse()
 for target in particle_targets:
  if target.is_ancestor_of(from_node):
   return target

 if from_node is CanvasItem and from_node.get_canvas_layer_node() != null:
  return from_node.get_canvas_layer_node()
 else:
  return get_tree().current_scene


func take_screenshot() -> Image:
 taking_screenshot.emit()
 await RenderingServer.frame_post_draw
 return get_window().get_texture().get_image()
