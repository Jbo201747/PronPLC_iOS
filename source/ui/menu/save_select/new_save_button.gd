extends MarginContainer

signal pressed

@onready var button: Button = %Button


func _ready() -> void :
 button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 pressed.emit()
