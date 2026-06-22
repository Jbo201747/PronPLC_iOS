class_name SelectorIcon extends Control


signal pressed


@onready var button: Button = %Button
@onready var hover_handler: HoverHandler = %HoverHandler


func _ready() -> void :
 button.pressed.connect(_on_button_pressed)


func init_select_state(_selected: bool) -> void :
 pass


func nudge() -> void :
 pass


func select() -> void :
 pass


func deselect() -> void :
 pass


func select_failed() -> void :
 pass


func is_selectable() -> bool:
 return true


func _on_button_pressed() -> void :
 pressed.emit()
