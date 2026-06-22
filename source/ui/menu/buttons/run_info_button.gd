@tool
class_name RunInfoButton extends MainMenuButton


@export var title: String = "":
 set(value):
  title = value
  update_title()
@export var use_string_key: = true
@export var show_locked_character: bool = false


@onready var title_label: Label = %Title
@onready var character_icon: Sprite2D = %CharacterIcon
@onready var difficulty_icon: Sprite2D = %DifficultyIcon
@onready var description_one: Label = %DescriptionOne
@onready var description_two: Label = %DescriptionTwo


func _ready() -> void :
 super._ready()
 update_title()
 character_icon.show_locked_character = show_locked_character


func update_title() -> void :
 if is_node_ready():
  if use_string_key and StringManager.has_string(title):
   title_label.text = StringManager.get_string(title)
  else:
   title_label.text = title


func set_character(id: String, trans: bool = false):
 character_icon.set_character(id, trans)


func set_difficulty(id: int):
 difficulty_icon.frame = id


func set_description(line_one: String, line_two: String = "") -> void :
 description_one.text = line_one
 description_two.text = line_two


func set_icons_visible(icons_visible: bool) -> void :
 %RunIcons.visible = icons_visible
