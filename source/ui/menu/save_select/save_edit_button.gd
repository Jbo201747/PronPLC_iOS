@tool
class_name SaveEditButton extends Control

signal button_down
signal button_up
signal pressed

@export var string_identifier: String = "":
 set(value):
  string_identifier = value
  %MenuIcon.string_identifier = string_identifier
@export var frame: int = 0:
 set(value):
  frame = value
  %MenuIcon.frame = value
@onready var button: Button = %Button


func _on_button_down() -> void :
 button_down.emit()


func _on_button_up() -> void :
 button_up.emit()


func _on_button_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 pressed.emit()


func _on_button_mouse_exited() -> void :
 mouse_exited.emit()
