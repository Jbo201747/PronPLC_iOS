class_name MainMenuButton extends MenuPanel


signal pressed

@export var opens_menu: MenuPanel
@export var action: StringName = &""
@export var glyph_action: StringName = &""
@export var enabled_theme: StringName = &""
@export var disabled_theme: StringName = &""
@export var disabled_shadows: Array[MenuPageShadow] = []

var disabled: = false

@onready var hover_handler = %HoverHandler
@onready var button: ActionButton = %Button
@onready var action_glyph: ActionGlyph = %ActionGlyph


func _ready() -> void :
 super._ready()
 active_changed.connect(_on_active_changed)
 button.action = action

 if action == &"" and glyph_action == &"":
  action_glyph.action = &""
 else:
  action_glyph.action = glyph_action if glyph_action != &"" else action


func _on_button_pressed() -> void :
 if active and not disabled:
  AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
  Game.menu_shake()
  pressed.emit()
  if opens_menu != null and menu_controller != null:
   AudioManager.play_sound(Sounds.UI.FORWARD_PAPER)
   menu_controller.set_menu(opens_menu)


func update_hover_handler() -> void :
 var should_be_disabled: = disabled or not active
 if hover_handler.disabled and not should_be_disabled:
  hover_handler.resume()
 elif not hover_handler.disabled and should_be_disabled:
  hover_handler.stop(true)


func update_theme() -> void :
 if disabled:
  if disabled_theme != &"":
   panel.theme_type_variation = disabled_theme
 else:
  if enabled_theme != &"":
   panel.theme_type_variation = enabled_theme


func disable() -> void :
 disabled = true
 update_hover_handler()

 for shadow in disabled_shadows:
  shadow.set_menu_disabled(true)

 update_theme()


func enable() -> void :
 disabled = false
 update_hover_handler()

 for shadow in disabled_shadows:
  shadow.set_menu_disabled(false)

 update_theme()


func set_disabled(is_disabled: bool) -> void :
 if is_disabled:
  disable()
 else:
  enable()


func _on_active_changed() -> void :
 update_hover_handler()


func get_focus_controls() -> Array[Control]:
 return [ %Button]


func can_grab_focus() -> bool:
 return not disabled
