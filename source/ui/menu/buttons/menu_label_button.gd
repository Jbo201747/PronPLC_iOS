@tool
extends "res://source/ui/menu/buttons/menu_button.gd"


@export var text: String = "":
 set(value):
  text = value
  update_label()
@export var use_string_key: bool = true
@export var shrink_to_bounds: float = 70.0

@onready var label: Label = %Label
@onready var info_label: Label = %InfoLabel


func _ready() -> void :
 super._ready()
 update_label()


func update_label() -> void :
 if is_node_ready():
  if use_string_key and StringManager.has_string(text):
   label.text = StringManager.get_string(text)
  else:
   label.text = text

  Util.shrink_label_to_bounds(label, shrink_to_bounds, 13)


func set_info_text(info_text: String = "") -> void :
 if info_text == "":
  info_label.visible = false
 else:
  info_label.text = info_text
  info_label.visible = true
