class_name DifficultySelector extends MenuPanel

signal selected

const ICON_SCENE: PackedScene = preload("res://source/ui/menu/character_select/difficulty_selector_icon.tscn")

var selected_difficulty: int = 0
var icons_instantiated: = false

@onready var icon_selector: IconSelector = %IconSelector


func instantiate_icons() -> void :
 var icons: Array[SelectorIcon] = []
 for i in Globals.DIFFICULTY_COUNT:
  var icon: DifficultySelectorIcon = ICON_SCENE.instantiate()
  icon.difficulty = i
  icons.append(icon)

 icon_selector.set_icons(icons)
 icons_instantiated = true


func update_labels():
 %Title.text = StringManager.get_string("difficulty/clearance", {
  name = StringManager.get_string("difficulty/" + str(selected_difficulty) + "/name")
 })
 %Description.text = StringManager.get_string("difficulty/" + str(selected_difficulty) + "/description")


func select_difficulty(difficulty: int):
 selected_difficulty = difficulty
 update_labels()
 selected.emit()


func set_character(character: String):
 var target_difficulty = SaveManager.get_save_data().selected_character_difficulty[character]
 if not Globals.is_difficulty_unlocked(target_difficulty, character):
  target_difficulty = 0

 select_difficulty(target_difficulty)

 for icon in icon_selector.icons:
  icon.character = character

 icon_selector.set_initial_selection(selected_difficulty)


func _on_icon_selector_selected(icon: DifficultySelectorIcon) -> void :
 select_difficulty(icon.difficulty)


func _on_start_appearing() -> void :
 if not icons_instantiated:
  instantiate_icons()

 var selected_character = SaveManager.get_save_data().selected_character
 set_character(selected_character)


func get_focus_controls() -> Array[Control]:
 return [icon_selector]
