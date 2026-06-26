class_name MainMenu extends Control


const TileStatus = Globals.TileStatus
const RANDOM_STATUSES = [
 TileStatus.ACID, 
 TileStatus.ASH, 
 TileStatus.BLEED, 
 TileStatus.BOMB, 
 TileStatus.BRUISE, 
 TileStatus.CANDY, 
 TileStatus.CRIT, 
 TileStatus.CURSED, 
 TileStatus.ENHANCED, 
 TileStatus.FROZEN, 
 TileStatus.GAY, 
 TileStatus.POISON, 
 TileStatus.POOP, 
 TileStatus.SPICY, 
]

var tile_scene = preload("res://source/tile/tile.tscn")

var title_tiles = []
var random_status = TileStatus.DEFAULT

var title_fade_tween: Tween

@onready var background = $Background
@onready var screen_wipe: ScreenWipe = %ScreenWipe
@onready var menu_controller: MenuController = %MenuController
@onready var version_label: Label = %VersionLabel
@onready var cutscene: CutscenePlayer = %Cutscene


func _ready():
 DailyManager.set_process(true)
 DailyManager.updated_daily.connect(update_daily_button)

 InputManager.update_actions()
 Game.running_from_menu = not Game.debug_character_select
 version_label.text = SaveManager.game_version
 random_status = RANDOM_STATUSES.pick_random()

 set_background_for_saved_run()

 Bridge.clear_rich_presence()

 AudioManager.kill_effects()

 if Util.is_mobile():
  AudioManager.play_music(Globals.MUSIC.AUTHOR)

 if SaveManager.has_valid_selected_save() and Bridge.leaderboards_available:
  var save: = SaveManager.get_save()
  save.try_upload_stored_scores()

 if Bridge.is_debug_build():
  print_debug_reports()

 if not Game.exiting_to_menu and not Game.debug_character_select:
  if Util.is_mobile():
   screen_wipe.uncover()
  else:
   screen_wipe.cover()
   cutscene.play_cutscene("vanity")
   await cutscene.finished
   screen_wipe.wipe_out()
 else:
  Game.exiting_to_menu = false
  screen_wipe.wipe_out()

 if Game.debug_character_select:
  Game.debug_character_select = false
  %CharacterSelect.can_close = false
  menu_controller.set_menu( %CharacterSelect)
 else:
  menu_controller.set_menu( %TitleMenu)

 if not Util.is_mobile():
  AudioManager.play_music(Globals.MUSIC.AUTHOR)


func _process(delta):
 background.scroll_base_offset += Vector2(-32.0 * delta, 0.0)


func _enter_tree() -> void :
 Game.main_menu = self


func _exit_tree() -> void :
 Game.main_menu = null


func print_debug_reports() -> void :
 Globals.print_spell_report()
 print("Champion count: ", Enemies.SHADOWS.values().size())


func hide_title():
 if title_fade_tween != null:
  title_fade_tween.kill()

 title_fade_tween = create_tween()
 title_fade_tween.tween_property( %Title, "modulate", Color.TRANSPARENT, 0.1)


func show_title():
 if title_fade_tween != null:
  title_fade_tween.kill()

 title_fade_tween = create_tween()
 title_fade_tween.tween_property( %Title, "modulate", Color.WHITE, 0.1)


func set_background_for_saved_run() -> void :
 var use_act_bg: int = 0

 if SaveManager.has_valid_selected_save():
  var save: = SaveManager.get_save()
  var saved_daily: Dictionary = save.get_saved_daily(false).metadata
  var saved_run: Dictionary = save.get_saved_run(false).metadata
  if "last_played" not in saved_daily:
   saved_daily.has_run = false

  if "last_played" not in saved_run:
   saved_run.has_run = false

  if saved_daily.has_run and saved_run.has_run:
   if saved_daily.last_played > saved_run.last_played:
    use_act_bg = saved_daily.act
   else:
    use_act_bg = saved_run.act
  elif saved_daily.has_run:
   use_act_bg = saved_daily.act
  elif saved_run.has_run:
   use_act_bg = saved_run.act

 background.set_background_for_act(use_act_bg)
 background.initialize_layers()
 background.reseed(Game.random)
 background.play_pattern("loop")


func update_daily_button():
 var daily_button: RunInfoButton = %DailyButton

 var can_view_leaderboards: = DailyManager.can_view_leaderboards()
 %LeaderboardButton.forced_hidden = not can_view_leaderboards

 if not Bridge.leaderboards_available:
  %LeaderboardButton.set_disabled(true)
 else:
  %LeaderboardButton.set_disabled(false)

 daily_button.title = "menu/main/daily"

 if not Bridge.dailies_available:
  daily_button.set_icons_visible(false)
  if Util.is_mobile():
   daily_button.set_description("")
  else:
   daily_button.set_description(StringManager.get_string("menu/leaderboard/unavailable"))
  daily_button.set_disabled(true)
  return

 if not DailyManager.can_view_daily() or DailyManager.updating_daily:
  daily_button.set_icons_visible(false)
  if DailyManager.updating_daily:
   daily_button.set_description(StringManager.get_string("menu/main/daily_updating"))
  else:
   daily_button.set_description("")
  daily_button.set_disabled(true)
  return

 var current_daily: Daily = DailyManager.current_daily
 var countdown: = DailyManager.get_countdown_string()
 daily_button.set_icons_visible(true)
 daily_button.set_character(current_daily.character, Globals.is_character_trans(current_daily.character, current_daily.difficulty))
 daily_button.set_difficulty(current_daily.difficulty)
 daily_button.set_disabled(false)

 if DailyManager.has_saved_daily():
  var playable_info: = DailyManager.get_saved_daily_playable()
  daily_button.set_disabled( not playable_info.playable)
  if not playable_info.playable:
   daily_button.set_description(countdown, playable_info.warning)
  else:
   daily_button.set_description(countdown, StringManager.get_string("menu/main/continue"))
 else:
  daily_button.set_description(countdown)

  if DailyManager.can_play_daily():
   daily_button.title = "menu/main/daily"
   if DailyManager.current_daily_friends > 0:
    daily_button.set_description(
     countdown, 
     StringManager.get_string("menu/main/daily_friends", {count = DailyManager.current_daily_friends})
    )
  elif DailyManager.can_view_leaderboard():
   daily_button.title = "menu/main/leaderboard"
   %LeaderboardButton.forced_hidden = true
  else:
   if not ModLoader.get_active_mod_ids(true).is_empty():
    daily_button.set_description(countdown, StringManager.get_string("menu/main/daily_mods"))
   daily_button.set_disabled(true)


func update_continue_info():
 var continue_button: RunInfoButton = %ContinueButton
 var save: = SaveManager.get_save()
 var saved_run = save.get_saved_run(false).metadata

 var playable_info: = SaveFile.get_run_playable(saved_run, false)
 if playable_info.daily_mismatch:
  save.clear_saved_run()
  playable_info.playable = false

 if playable_info.playable:
  continue_button.set_character(saved_run.character, Globals.is_character_trans(saved_run.character, saved_run.difficulty))
  continue_button.set_difficulty(saved_run.difficulty)

 continue_button.set_description(playable_info.warning)

 continue_button.set_icons_visible(playable_info.playable)
 continue_button.set_disabled( not playable_info.playable)


func generate_title_tiles(faces):
 var tiles: Array[Tile] = []
 for face in faces:
  var tile: Tile = tile_scene.instantiate()
  tile.is_preview = true
  tile.z_index = -1
  add_child(tile)
  tile.tile_collision.mouse_filter = MOUSE_FILTER_IGNORE

  if face.to_lower() != face:
   tile.set_face(face.to_lower())
   tile.add_status(TileStatus.CAPITAL)
  else:
   tile.set_face(face)

  if face[-1] == ".":
   tile.add_status(TileStatus.PERIOD)
   face = face.trim_suffix(".")

  if randi_range(1, 3) == 1:
   tile.set_type(Globals.TileType.DEFENSE)




  tiles.append(tile)

 title_tiles.append_array(tiles)

 return tiles


func _on_continue_button_pressed() -> void :
 screen_wipe.wipe_in()
 await screen_wipe.screen_covered
 Game.load_run(SaveManager.get_save().get_saved_run(true))


func _on_quit_button_pressed() -> void :
 Game.quit()


func _on_daily_button_pressed() -> void :
 var has_saved_daily: = DailyManager.has_saved_daily()
 if not has_saved_daily and not DailyManager.can_play_daily():
  if DailyManager.can_view_leaderboard():
   menu_controller.set_menu( %LeaderboardMenu)

  return

 AudioManager.fade_music()

 screen_wipe.wipe_in()
 await screen_wipe.screen_covered

 if not has_saved_daily:
  Game.start_daily_run()
 else:
  Game.load_run(SaveManager.get_save().get_saved_daily(true))


func _on_continue_button_start_appearing() -> void :
 update_continue_info()


func _on_phonebook_button_start_appearing() -> void :
 %PhonebookButton.set_notification(false)

 var has_valid_save: = SaveManager.has_valid_selected_save()
 if has_valid_save:
  var save: = SaveManager.get_save()
  var unlocked: = save.is_phonebook_unlocked()
  %PhonebookButton.set_disabled( not unlocked)
  if unlocked:
   %PhonebookButton.set_notification(save.is_phonebook_unread())
 else:
  %PhonebookButton.set_disabled(true)


func _on_play_button_start_appearing() -> void :
 %PlayButton.set_disabled( not SaveManager.has_valid_selected_save())


func _on_extras_button_start_appearing() -> void :
 %ExtrasButton.set_disabled( not SaveManager.has_valid_selected_save())


func _on_new_run_button_start_appearing() -> void :
 var has_valid_save = SaveManager.has_valid_selected_save()
 %NewRunButton.set_disabled( not has_valid_save)


func _on_menu_controller_active_menu_changed() -> void :
 if menu_controller.active_menu != null and menu_controller.active_menu.full_screen_menu:
  hide_title()
 else:
  show_title()


func _on_play_menu_start_appearing() -> void :
 DailyManager.check_daily()
 DailyManager.refresh_daily()
 update_daily_button()
