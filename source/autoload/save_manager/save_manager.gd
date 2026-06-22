extends Node


signal save_changed
signal updated_settings
signal updated_cursor_scale
signal stored_save

var options
var selected_save: SaveFile
var last_monitor_count: int = -1

const SAVE_FORMAT_VERSION = 1

const FIRST_SAVE_NAME = "Save 1"
const OPTIONS_FILE = "user://options.dat"
const SAVES_FOLDER = "user://saves/"

const SAVE_FILENAME = "data.save"
const RUN_FILENAME = "run.save"
const DAILY_FILENAME = "daily.save"

var OPTIONS_DEFAULTS = {
 fullscreen_setting = true, 
 monitor = 0, 
 resolution = Vector2i(960, 540), 
 pixel_perfect = false, 
 sound_setting = 0.5, 
 music_setting = 0.5, 
 screenshake_setting = 1.0, 
 menu_shake_setting = true, 
 unlocks_disabled = false, 
 battle_timer = true, 
 show_crit_chance = false, 
 selected_save = null, 
 music_muted = false, 
 sound_muted = false, 
 hide_default_tile_tooltips = false, 
 vibration_enabled = true, 
 spell_gamepad_layout = 0, 
 cursor_scale = 0, 
 gamepad_prompts = true, 
 hide_steam_info = false, 
 skip_repeat_dialogue = false, 
 max_fps = 120, 
}

var corrupted_saves: Dictionary[String, bool] = {}

@onready var game_version = ProjectSettings.get_setting("application/config/version")


func _ready():
 ensure_saves_folder_exists()
 load_options()
 SaveMigration.migrate_files_to_folders()
 ensure_selected_save(true)
 Game.exiting_game.connect(_on_exiting_game)


func ensure_saves_folder_exists() -> void :
 var saves_path: = SAVES_FOLDER.trim_suffix("/")
 if DirAccess.dir_exists_absolute(saves_path):
  return

 var err: Error = DirAccess.make_dir_recursive_absolute(saves_path)
 if err != OK:
  push_warning("Failed to create saves folder: error ", err)


func _on_exiting_game() -> void :
 store_selected_save()
 store_options()


func ensure_selected_save(load_if_selected = false):
 var available_saves = get_available_saves()


 for save in available_saves:
  if save.name == options.selected_save:
   if load_if_selected:
    load_selected_save()

   return

 if available_saves.size() == 0:
  create_new_save_file(FIRST_SAVE_NAME)
  select_save(FIRST_SAVE_NAME)
 else:
  select_save(available_saves[0].name)


func load_options():
 if FileAccess.file_exists(OPTIONS_FILE):
  var file = FileAccess.open(OPTIONS_FILE, FileAccess.READ)
  if file:
   options = file.get_var()

 var options_first_initialization = false
 if options == null:
  options_first_initialization = true
  initialize_options()

 set_default_options()
 update_settings(true)
 updated_settings.emit()

 if options_first_initialization:
  store_options()


func store_options():
 var file = FileAccess.open(OPTIONS_FILE, FileAccess.WRITE)
 file.store_var(options)


func initialize_options():
 options = {}


func set_default_options():
 var defaults = OPTIONS_DEFAULTS.duplicate()
 if Bridge.is_steam_deck:
  defaults.resolution = Vector2i(1280, 800)

 Util.deep_default(options, defaults)


func get_save_directory_path(save_name: String) -> String:
 return SAVES_FOLDER + save_name.validate_filename()


func save_name_available(save_name: String) -> bool:
 var save_file: = SaveFile.new(save_name)
 return not save_file.has_directory()


func get_available_saves() -> Array[SaveFile]:
 var available_saves: Array[SaveFile] = []
 if not DirAccess.dir_exists_absolute(SAVES_FOLDER.trim_suffix("/")):
  return available_saves

 for save_name in DirAccess.get_directories_at(SAVES_FOLDER):
  var save_file: = SaveFile.new(save_name)

  if save_name in corrupted_saves:


   save_file.load_file(true)
  else:
   save_file.load_file(false)

  if save_file.corrupt:
   push_warning("Corrupted Save? ", save_name)

  if save_file.metadata_loaded:
   available_saves.append(save_file)

 available_saves.sort_custom( func(a, b): return a.is_selected() or (a.name < b.name and not b.is_selected()))

 return available_saves


func get_first_available_save_name(prefix = "Save", use_parentheses = false, use_initial = false) -> String:
 if use_initial and save_name_available(prefix):
  return prefix

 var first_available_save = 1
 while true:
  var number = str(first_available_save)
  if use_parentheses:
   number = "(" + number + ")"

  var save_name = prefix + " " + number
  if save_name_available(save_name):
   return save_name

  first_available_save += 1

 return ""


func create_new_save_file(save_name: String) -> void :
 if save_name == null:
  save_name = get_first_available_save_name()

 var new_file: = SaveFile.create_new(save_name)
 new_file.store_file()


func get_save() -> SaveFile:
 return selected_save


func get_selected_save_name() -> Variant:
 return options.selected_save


func load_selected_save():
 var selected_save_name = get_selected_save_name()
 if selected_save_name == null:
  push_error("No save file selected.")
  return

 selected_save = SaveFile.new(selected_save_name)
 selected_save.load_file(true)

 if not selected_save.data_loaded or selected_save.corrupt:
  deselect_save()
  corrupted_saves[selected_save_name] = true
  push_error("Failed to load selected save file. Save corrupted?")
 elif selected_save_name in corrupted_saves:
  corrupted_saves.erase(selected_save_name)

 if has_valid_selected_save():
  StringManager.set_data_source("stats", {
   fastest_win_addict = selected_save.get_character_fastest_win.bind(Globals.CHARACTERS.ADDICT), 
  })
 else:
  StringManager.set_data_source("stats", {})

 save_changed.emit()


func store_selected_save():
 if has_valid_selected_save():
  selected_save.store_file()
  stored_save.emit()


func select_save(save_name):
 store_selected_save()
 options.selected_save = save_name
 load_selected_save()
 store_options()


func deselect_save():
 selected_save = null
 options.selected_save = null
 store_options()


func has_valid_selected_save() -> bool:
 return options.selected_save != null and selected_save != null and selected_save.data_loaded


func get_save_data():
 return selected_save.data



func update_settings(is_initial: bool = false):
 update_pixel_perfect()
 update_fps()
 update_window(is_initial)
 update_music()
 update_sound()
 update_mute()


func update_fps() -> void :
 Engine.max_fps = maxi(options.max_fps, 30)


func update_window(is_initial: bool = false) -> void :
 var target_monitors: = get_target_monitors()
 last_monitor_count = target_monitors.size()
 if options.monitor not in target_monitors:
  set_monitor_setting(0)
  return

 var target_resolutions: = get_target_resolutions()
 if options.resolution not in target_resolutions:
  var closest_resolution: Vector2i = Vector2i.MIN
  var closest_distance: float = INF
  for resolution in target_resolutions:
   var dist: = resolution.distance_to(options.resolution)
   if dist < closest_distance:
    closest_resolution = resolution
    closest_distance = dist

  set_resolution_setting(closest_resolution)
  return

 var window: = get_window()
 if window.current_screen != options.monitor:
  var was_borderless: = window.borderless
  window.borderless = false
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
  window.current_screen = options.monitor
  window.move_to_center()
  window.borderless = was_borderless

 if options.fullscreen_setting:
  get_window().move_to_center()
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
  return
 else:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

 var old_size: = window.size
 var new_size: Vector2i = options.resolution

 var set_borderless: bool = new_size == DisplayServer.screen_get_size(options.monitor)
 var changed_borderless: = false
 if window.borderless != set_borderless:
  changed_borderless = true
  window.borderless = set_borderless
  if not window.borderless:
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

 if new_size != old_size or is_initial or changed_borderless:
  window.size = new_size


  window.current_screen = options.monitor
  window.move_to_center()


func get_target_resolutions() -> Array[Vector2i]:
 var target_resolutions: Array[Vector2i] = []
 var max_scale: int

 var screen_size = DisplayServer.screen_get_size(options.monitor)
 if screen_size not in target_resolutions:
  target_resolutions.append(screen_size)
  max_scale = maxi(max_scale, mini(screen_size.x / 480, screen_size.y / 270))

 for i in max_scale:
  var scaled: = Vector2i(480, 270) * (i + 1)
  if scaled not in target_resolutions:
   target_resolutions.append(scaled)

 target_resolutions.sort()
 return target_resolutions


func get_target_monitors() -> Array[int]:
 var monitors: Array[int] = []
 for i in DisplayServer.get_screen_count():
  monitors.append(i)

 return monitors


func update_pixel_perfect() -> void :
 if not options.pixel_perfect:
  get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
 else:
  get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER


func update_music():
 var music_idx = AudioServer.get_bus_index("Music")
 AudioServer.set_bus_volume_db(music_idx, linear_to_db(options.music_setting))


func update_sound():
 var sound_idx = AudioServer.get_bus_index("Sound")
 AudioServer.set_bus_volume_db(sound_idx, linear_to_db(options.sound_setting))

 var sound_lowpass_idx = AudioServer.get_bus_index("SoundLowpass")
 AudioServer.set_bus_volume_db(sound_lowpass_idx, linear_to_db(options.sound_setting))


func update_mute():
 var music_bus = AudioServer.get_bus_index("Music")
 AudioServer.set_bus_mute(music_bus, options.music_muted)

 var sound_bus = AudioServer.get_bus_index("Sound")
 AudioServer.set_bus_mute(sound_bus, options.sound_muted)

 var sound_lowpass_bus = AudioServer.get_bus_index("SoundLowpass")
 AudioServer.set_bus_mute(sound_lowpass_bus, options.sound_muted)


func set_fullscreen_setting(value):
 options.fullscreen_setting = value
 update_window()
 updated_settings.emit()


func get_fullscreen_setting():
 return options.fullscreen_setting


func set_monitor_setting(value: int) -> void :
 options.monitor = value
 update_window()
 updated_settings.emit()


func get_monitor_setting() -> int:
 return options.monitor


func set_resolution_setting(value: Vector2i) -> void :
 options.resolution = value
 update_window()
 updated_settings.emit()


func get_resolution_setting() -> Vector2i:
 return options.resolution


func get_max_fps_options() -> Array[int]:
 return [0, 60, 120, 240]


func set_max_fps(value: int) -> void :
 options.max_fps = value
 update_fps()
 updated_settings.emit()


func get_max_fps() -> int:
 return options.max_fps


func set_pixel_perfect(value: bool) -> void :
 options.pixel_perfect = value
 update_pixel_perfect()
 updated_settings.emit()


func get_pixel_perfect() -> bool:
 return options.pixel_perfect


func set_music_setting(value, unmute: = false):
 if unmute:
  set_music_muted(false)

 options.music_setting = value
 update_music()
 updated_settings.emit()


func get_music_setting(include_mute: = false):
 if not include_mute or not get_music_muted():
  return options.music_setting
 else:
  return 0.0


func set_sound_setting(value, unmute: = false):
 if unmute:
  set_sound_muted(false)

 options.sound_setting = value
 update_sound()
 updated_settings.emit()


func get_sound_setting(include_mute: = false):
 if not include_mute or not get_sound_muted():
  return options.sound_setting
 else:
  return 0.0


func set_screenshake_setting(value):
 options.screenshake_setting = value
 updated_settings.emit()


func get_screenshake_setting():
 return options.screenshake_setting


func set_menu_shake_setting(value):
 options.menu_shake_setting = value
 updated_settings.emit()


func get_menu_shake_setting():
 return options.menu_shake_setting


func set_unlocks_disabled(value):
 options.unlocks_disabled = value
 updated_settings.emit()


func get_unlocks_disabled() -> bool:
 return options.unlocks_disabled


func set_battle_timer_enabled(value):
 options.battle_timer = value
 updated_settings.emit()


func get_battle_timer_enabled() -> bool:
 return options.battle_timer


func set_show_crit_chance_enabled(value: bool):
 options.show_crit_chance = value
 updated_settings.emit()


func get_show_crit_chance_enabled() -> bool:
 return options.show_crit_chance


func set_hide_default_tile_tooltips_enabled(value: bool):
 options.hide_default_tile_tooltips = value
 updated_settings.emit()


func get_hide_default_tile_tooltips_enabled() -> bool:
 return options.hide_default_tile_tooltips


func set_skip_repeat_dialogue(value: bool) -> void :
 options.skip_repeat_dialogue = value
 updated_settings.emit()


func get_skip_repeat_dialogue() -> bool:
 return options.skip_repeat_dialogue


func set_music_muted(value: bool) -> void :
 options.music_muted = value
 update_mute()
 updated_settings.emit()


func get_music_muted() -> bool:
 return options.music_muted


func set_sound_muted(value: bool) -> void :
 options.sound_muted = value
 update_mute()
 updated_settings.emit()


func get_sound_muted() -> bool:
 return options.sound_muted


func set_spell_gamepad_layout(value: int) -> void :
 options.spell_gamepad_layout = value
 updated_settings.emit()


func get_spell_gamepad_layout() -> int:
 return options.spell_gamepad_layout


func set_vibration_enabled(value: bool) -> void :
 options.vibration_enabled = value
 updated_settings.emit()


func get_vibration_enabled() -> bool:
 return options.vibration_enabled


func set_cursor_scale(value: int) -> void :
 options.cursor_scale = value
 updated_cursor_scale.emit()
 updated_settings.emit()


func get_cursor_scale() -> int:
 return options.cursor_scale


func set_gamepad_prompts_enabled(value: bool) -> void :
 options.gamepad_prompts = value
 updated_settings.emit()


func get_gamepad_prompts_enabled() -> bool:
 return options.gamepad_prompts


func set_hide_steam_info(value: bool) -> void :
 options.hide_steam_info = value
 updated_settings.emit()


func get_hide_steam_info() -> bool:
 return options.hide_steam_info


func is_version_lower(version: String, compare_to: String) -> bool:
 if version == compare_to:
  return false

 var split: = version.split(".")
 var compare_split: = compare_to.split(".")

 var split_size: = split.size()
 var compare_size: = compare_split.size()


 for i in split_size:
  if i < compare_size:


   var subversion: = split[i]
   var compare_subversion: = compare_split[i]
   if subversion.is_valid_float() and compare_subversion.is_valid_float():
    var subversion_float: = subversion.to_float()
    var compare_subversion_float: = compare_subversion.to_float()
    if subversion_float < compare_subversion_float:
     return true
    elif subversion_float > compare_subversion_float:
     return false
   elif subversion < compare_subversion:
    return true
   elif subversion > compare_subversion:
    return false
  else:



   return false




 if split_size != compare_size:
  return true


 else:
  return false
