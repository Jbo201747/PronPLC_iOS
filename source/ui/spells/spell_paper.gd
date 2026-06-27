class_name SpellPaper extends Node2D

signal pressed
signal focus_entered
signal focus_exited

var spell: PlayerSpell = null

const MOBILE_TAP_DEDUPE_MS = 150

var normal_texture: = preload("res://arte/ui/spell_paper.png")
var cursed_texture: = preload("res://arte/ui/spell_paper_cursed.png")
var last_mobile_tap_msec: = 0

@onready var sprite: Sprite2D = %Sprite
@onready var overlay_sprite: Sprite2D = %SpellPaperOverlay
@onready var hover_handler: HoverHandler = %HoverHandler
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var button: Button = %Button


func _ready() -> void :
 if not Game.is_in_run():
  return

 if get_parent() is PlayerSpell:
  spell = get_parent()
  Game.player.selection_started.connect(_on_player_selection_started)
  Game.player.selection_finished.connect(_on_player_selection_finished)
  if Util.is_mobile():
   button.mouse_filter = Control.MOUSE_FILTER_STOP
   button.gui_input.connect(_on_mobile_button_gui_input)
 else:
  hover_handler.stop(true)


func set_cursed(cursed: bool) -> void :
 if cursed:
  sprite.texture = cursed_texture
  overlay_sprite.texture = cursed_texture
 else:
  sprite.texture = normal_texture
  overlay_sprite.texture = normal_texture


func disable_button() -> void :
 button.disabled = true
 update_hover_handler()


func enable_button() -> void :
 button.disabled = false
 update_hover_handler()


func update_hover_handler():
 if button.disabled or anim_player.is_playing() and "selecting" not in anim_player.current_animation:
  hover_handler.stop(true)
 else:
  hover_handler.resume()


func is_active_spell():
 return Game.player.active_spell == spell.spell


func gain():
 anim_player.play("gain")
 await anim_player.animation_finished


func disappear(instant: = false):
 await anim_player.play_until_finished("disappear", instant)


func appear(instant: = false):
 await anim_player.play_until_finished("appear", instant)


func set_usable(usable: bool):
 if usable:
  sprite.frame = 1
 else:
  sprite.frame = 0


func _on_anim_player_current_animation_changed(_name: String) -> void :
 update_hover_handler()


func _on_button_pressed() -> void :
 anim_player.play("press")
 pressed.emit()


func _on_mobile_button_gui_input(event: InputEvent) -> void :
 if not _is_mobile_press_event(event):
  return

 if spell == null or not spell.is_clickable():
  return

 var now: = Time.get_ticks_msec()
 if now - last_mobile_tap_msec < MOBILE_TAP_DEDUPE_MS:
  return

 last_mobile_tap_msec = now
 _on_button_pressed()
 button.accept_event()


func _is_mobile_press_event(event: InputEvent) -> bool:
 if event is InputEventScreenTouch:
  return event.pressed

 return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _on_player_selection_started() -> void :
 if is_active_spell():
  anim_player.queue("selecting")


func _on_player_selection_finished() -> void :
 if is_active_spell():
  if "selecting" in anim_player.get_queue():
   anim_player.clear_queue()
  elif anim_player.current_animation == "selecting":
   anim_player.play("stop_selecting")


func _on_button_focus_entered() -> void :
 focus_entered.emit()


func _on_button_focus_exited() -> void :
 focus_exited.emit()
