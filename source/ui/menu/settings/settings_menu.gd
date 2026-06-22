extends MenuPanel


var resolution_to_option: Dictionary[Vector2i, int] = {}
var fps_to_option: Dictionary[int, int] = {}
var last_screen_count: int = -1

@onready var top_marker: Marker2D = %TopMarker
@onready var sectioned_panel: SectionedPanel = %SectionedPanel
@onready var tab_controller: TabController = %TabController


func _ready():
 SaveManager.updated_settings.connect(update_settings)
 update_settings()

 %HideSteamInfo.visible = Bridge.has_steam()
 %Fullscreen.set_setting_methods(SaveManager.get_fullscreen_setting, SaveManager.set_fullscreen_setting)
 %Resolution.set_setting_methods(get_resolution_setting, set_resolution_setting)
 %Monitor.set_setting_methods(SaveManager.get_monitor_setting, SaveManager.set_monitor_setting)
 %MaxFPS.set_setting_methods(get_max_fps_setting, set_max_fps_setting)
 %Music.set_setting_methods(SaveManager.get_music_setting.bind(true), SaveManager.set_music_setting.bind(true))
 %Sound.set_setting_methods(SaveManager.get_sound_setting.bind(true), SaveManager.set_sound_setting.bind(true))
 %Screenshake.set_setting_methods(SaveManager.get_screenshake_setting, SaveManager.set_screenshake_setting)
 %MenuShake.set_setting_methods(SaveManager.get_menu_shake_setting, SaveManager.set_menu_shake_setting)
 %BattleTimer.set_setting_methods(SaveManager.get_battle_timer_enabled, SaveManager.set_battle_timer_enabled)
 %CritChance.set_setting_methods(SaveManager.get_show_crit_chance_enabled, SaveManager.set_show_crit_chance_enabled)
 %HideDefaultTileTooltips.set_setting_methods(SaveManager.get_hide_default_tile_tooltips_enabled, SaveManager.set_hide_default_tile_tooltips_enabled)
 %SpellGamepadLayout.set_setting_methods(SaveManager.get_spell_gamepad_layout, SaveManager.set_spell_gamepad_layout)
 %SkipRepeatDialogue.set_setting_methods(SaveManager.get_skip_repeat_dialogue, SaveManager.set_skip_repeat_dialogue)
 %Vibration.set_setting_methods(SaveManager.get_vibration_enabled, SaveManager.set_vibration_enabled)
 %GamepadPrompts.set_setting_methods(SaveManager.get_gamepad_prompts_enabled, SaveManager.set_gamepad_prompts_enabled)
 %PixelPerfect.set_setting_methods(SaveManager.get_pixel_perfect, SaveManager.set_pixel_perfect)
 %Unlocks.set_setting_methods(SaveManager.get_unlocks_disabled, SaveManager.set_unlocks_disabled)
 %CursorScale.set_setting_methods(SaveManager.get_cursor_scale, SaveManager.set_cursor_scale)
 %HideSteamInfo.set_setting_methods(SaveManager.get_hide_steam_info, SaveManager.set_hide_steam_info)
 super._ready()
 last_screen_count = DisplayServer.get_screen_count()
 set_physics_process(false)


func _physics_process(_delta: float) -> void :
 if last_screen_count != DisplayServer.get_screen_count():
  SaveManager.update_window()
  SaveManager.updated_settings.emit()


func update_settings() -> void :
 %Resolution.disabled = SaveManager.get_fullscreen_setting()

 update_window_options()
 update_info_container()


func update_window_options() -> void :
 var monitor_setting: LabelSwitcherSetting = %Monitor

 var monitors: = SaveManager.get_target_monitors()
 var should_monitor_be_visible: = monitors.size() > 1
 monitor_setting.disabled = not should_monitor_be_visible
 if monitor_setting.visible != should_monitor_be_visible:
  var had_focus: = Util.has_focus(self, true)
  monitor_setting.visible = should_monitor_be_visible
  setup_internal_focus()
  if had_focus:
   grab_focus()

 var monitor_options: Array[String] = []
 for monitor in monitors:
  monitor_options.append(str(monitor))

 monitor_setting.options = monitor_options

 var resolutions: = SaveManager.get_target_resolutions()
 var resolution_options: Array[String] = []
 resolution_to_option.clear()
 for resolution in resolutions:
  resolution_options.append(str(resolution.x) + "x" + str(resolution.y))
  resolution_to_option[resolution] = resolution_options.size() - 1

 %Resolution.options = resolution_options

 var fps_strings: Array[String] = []
 var fps_options: = SaveManager.get_max_fps_options()
 for fps in fps_options:
  if fps == 0:
   fps_strings.append(StringManager.get_string("menu/settings/unlimited"))
  else:
   fps_strings.append(str(fps))

  fps_to_option[fps] = fps_strings.size() - 1

 %MaxFPS.options = fps_strings


func get_resolution_setting() -> int:
 var resolution: = SaveManager.get_resolution_setting()
 if resolution not in resolution_to_option:
  return maxi(1, SaveManager.get_target_resolutions().size() - 1)
 else:
  return resolution_to_option[resolution]


func set_resolution_setting(value: int) -> void :
 var resolution: Variant = resolution_to_option.find_key(value)
 if resolution is Vector2i:
  SaveManager.set_resolution_setting(resolution)


func get_max_fps_setting() -> int:
 var fps: = SaveManager.get_max_fps()
 if fps not in fps_to_option:
  return maxi(1, SaveManager.get_max_fps_options().size() - 1)
 else:
  return fps_to_option[fps]


func set_max_fps_setting(value: int) -> void :
 var max_fps: Variant = fps_to_option.find_key(value)
 if max_fps is int:
  SaveManager.set_max_fps(max_fps)


func _on_music_slider_drag_started():
 if Game.is_in_run():
  AudioManager.effects.pause.set_enabled(false)


func _on_music_slider_drag_ended():
 if Game.is_in_run():
  AudioManager.effects.pause.set_enabled(true)


func _on_start_appearing() -> void :
 tab_controller.set_active_tab(tab_controller.tabs[0], false)
 update_info_container()
 set_physics_process(true)


func update_info_container() -> void :
 var seed_label: Label = %SeedLabel
 var is_run: bool = Game.is_in_run()
 if is_run:
  %Unlocks.visible = false
  seed_label.visible = not Game.active_daily
  if seed_label.visible:
   seed_label.text = StringManager.get_string("menu/settings/seed", {seed = Game.main.rng.game.get_seed_hex()})
 else:
  %Unlocks.visible = true
  seed_label.visible = false

 %UnlocksDisabledLabel.text = StringManager.get_string("menu/settings/unlocks_disabled", {menu = not is_run, daily = is_run and Game.active_daily != null, seeded = is_run and Game.is_seeded and Game.active_daily == null})
 %UnlocksDisabledLabel.visible = AchievementManager.unlocking_disabled(true)
 sectioned_panel.update_panels()


func _on_start_disappearing() -> void :
 SaveManager.store_options()
 set_physics_process(false)


func _on_screenshake_value_changed() -> void :
 Game.menu_shake(true)


func get_focus_controls() -> Array[Control]:
 var settings: Array[Setting] = [
  %Fullscreen, 
  %PixelPerfect, 
  %Resolution, 
  %Monitor, 
  %Music, 
  %Sound, 
  %Screenshake, 
  %MenuShake, 
  %CursorScale, 
  %BattleTimer, 
  %CritChance, 
  %HideDefaultTileTooltips, 
  %SkipRepeatDialogue, 
  %HideSteamInfo, 
  %Unlocks, 
  %SpellGamepadLayout, 
  %Vibration, 
  %GamepadPrompts, 
 ]

 var focus_controls: Array[Control] = []
 for setting in settings:
  if setting.visible:
   focus_controls.append(setting.main_control)

 var input_guide_containers: Array[InputGuideContainer] = [
  %Hotkeys, 
  %Controller
 ]

 for container in input_guide_containers:
  if container.visible:
   for child in container.get_children():
    focus_controls.append(child)

 return focus_controls


func setup_focus_connections(focus_controls: Array[Control]) -> void :
 Util.set_control_focus_sequence(focus_controls, true)


func _on_vibration_value_changed() -> void :
 InputManager.vibrate(0.4, 0.1, 0.2)


func _on_tabs_tab_changed(_new_tab: TabButton) -> void :
 %InfoMarginContainer.visible = tab_controller.active_tab.string_key != "menu/settings/controls"
 sectioned_panel.update_panels()
