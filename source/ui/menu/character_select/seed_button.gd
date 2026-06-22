class_name SeedButton extends MainMenuButton


@onready var line_edit: LineEdit = %LineEdit


func _ready() -> void :
 %Label.text = StringManager.get_string("menu/character_select/seed")
 line_edit.placeholder_text = StringManager.get_string("menu/character_select/random")
 super._ready()


func _on_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 line_edit.mouse_filter = Control.MOUSE_FILTER_PASS
 line_edit.editable = true
 line_edit.selecting_enabled = true
 line_edit.placeholder_text = ""
 line_edit.grab_focus()
 line_edit.edit()

 if InputManager.get_input_mode() == InputManager.InputMode.CONTROLLER:
  Bridge.popup_keyboard(StringManager.get_string("menu/character_select/seed"), line_edit.max_length, line_edit.text)


func _on_line_edit_editing_toggled(toggled_on: bool) -> void :
 if not toggled_on:
  line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
  line_edit.editable = false
  line_edit.selecting_enabled = false
  line_edit.placeholder_text = StringManager.get_string("menu/character_select/random")


func get_seed() -> Variant:
 if active and line_edit.text != "":
  return line_edit.text.hex_to_int()
 else:
  return null


func _on_button_focus_entered() -> void :
 if button.has_focus(true):
  button.release_focus()
  InputManager.grab_initial_focus()


func start_appear() -> void :
 super.start_appear()
 line_edit.text = ""
