extends MenuPanel


@export var screen_wipe: ScreenWipe

var character: String:
 get():
  return character_selector.selected_character

var difficulty: int:
 get():
  return difficulty_selector.selected_difficulty

@onready var character_selector: CharacterSelector = %CharacterSelector
@onready var difficulty_selector: DifficultySelector = %DifficultySelector
@onready var start_button: MainMenuButton = %StartButton
@onready var seed_button: SeedButton = %SeedButton
@onready var win_streak: MenuPanel = %WinStreak


func _ready():
 position = Vector2.ZERO
 super._ready()


func animate_appear(instant: bool = false):
 if SaveManager.get_save_data().seen_tutorial:
  await MenuPanel.sequenced_appear([character_selector, difficulty_selector, win_streak, seed_button, start_button], instant)
 else:
  await MenuPanel.sequenced_appear([character_selector, difficulty_selector, start_button], instant)


func animate_disappear(instant: bool = false):
 await MenuPanel.sequenced_disappear([start_button, seed_button, win_streak, difficulty_selector, character_selector], instant)


func _on_start_button_pressed() -> void :
 if Globals.is_difficulty_unlocked(difficulty, character):
  Game.difficulty = difficulty
  if screen_wipe != null:
   AudioManager.fade_music()
   screen_wipe.wipe_in()
   await screen_wipe.screen_covered

  if SaveManager.get_save().has_saved_run():
   SaveManager.get_save().clear_saved_run(true)

  Game.start_run(character, seed_button.get_seed())


func _on_character_selector_selected() -> void :
 SaveManager.get_save_data().selected_character = character
 difficulty_selector.set_character(character)
 start_button.set_disabled( not Globals.is_character_unlocked(character))


func _on_difficulty_selector_selected() -> void :
 var save_data = SaveManager.get_save_data()
 save_data.selected_character_difficulty[character] = difficulty
 character_selector._on_difficulty_updated()


func get_focus_controls() -> Array[Control]:
 return [character_selector, difficulty_selector]


func setup_focus_connections(focus_controls: Array[Control]) -> void :
 Util.set_control_focus_sequence(focus_controls, true)


func _on_start_appearing() -> void :
 win_streak.label.text = str(SaveManager.get_save().stats.streak)
