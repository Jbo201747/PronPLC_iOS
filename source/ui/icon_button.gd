extends Node2D


signal pressed

const HOVER_POSITION = Vector2(0, -2)
const DEFAULT_POSITION = Vector2(0, 0)

var hover_tween = null

var disabled = false:
 set(value):
  disabled = value
  %Button.disabled = disabled
  hover_handler.set_disabled(disabled)

@onready var action_glyph: ActionGlyph = %ActionGlyph
@onready var anim: AnimationPlayer = %AnimPlayer
@onready var hover_handler: HoverHandler = %HoverHandler
@onready var tooltip_collision = %MenuTooltipCollision


func press() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 hover_handler.stop()
 anim.play("pressed")
 Game.screenshake(2, 0.16)
 pressed.emit()
 await anim.animation_finished

 if not disabled:
  hover_handler.resume()


func _on_button_pressed() -> void :
 press()
