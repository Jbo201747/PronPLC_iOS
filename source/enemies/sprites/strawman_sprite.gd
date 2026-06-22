@tool
extends BattleUnitSprite

signal bopped
signal touched

const DOWN_FRAME_REGION = Rect2(96, 0, 96, 128)

var touch_anim: = "xd"
var was_touched: = false
var beg_timer: = 0.0
var can_idle: = true
var can_xd = true
var touch_hovered = false
var horniness = 0:
 set(value):
  horniness = clamp(value, 0, 3)

@onready var face_anim_player = $Sprite / FaceOffset / Face / AnimPlayer
@onready var blush = $Sprite / FaceOffset / Face / Blush
@onready var sprite = $Sprite
@onready var beat_player = %BeatPlayer


func _init():
 if Engine.is_editor_hint():
  return

 bleed_blend = Globals.COLORS.SMOKE_SHIT

func is_idling() -> bool:
 if (
   (
    anim_player.is_playing()
    and anim_player.current_animation not in ["bop_down", "bop_up"]
   )
   or not can_idle):
  return false

 return true


func _bop() -> void :
 if not is_idling():
  return
 elif sprite.region_rect == DOWN_FRAME_REGION:
  anim_player.play("bop_up")
 else:
  anim_player.play("bop_down")

 bopped.emit()


func _physics_process(delta: float) -> void :
 if Engine.is_editor_hint():
  return

 if not can_xd or not is_idling():
  horniness = 0.0
  beg_timer = 0.0
  blush.modulate.a = 0.0
  was_touched = false
  return

 update_blush(delta)

 if beg_timer > 0.0:
  beg_timer -= delta

 if was_touched and horniness <= 0 and face_anim_player.current_animation != touch_anim:
  was_touched = false
  if beg_timer <= 0.0:
   play_sound(Sounds.STRAWMAN.DONT_STOP)
   beg_timer = 1.0


func _unhandled_input(input_event: InputEvent):
 if not can_xd or not is_idling() or Engine.is_editor_hint():
  return

 if input_event.is_action_pressed("primary_button") and touch_hovered:
  _touch()


func update_blush(delta: float) -> void :
 if horniness > 0:
  horniness -= delta

 var blush_amount = min(horniness, 1)
 blush.modulate.a = blush_amount










func play_touch_animation() -> void :
 if face_anim_player.current_animation == touch_anim:
  horniness += 0.2
  face_anim_player.seek(0)
 else:
  face_anim_player.play(touch_anim)


func _touch():
 touched.emit()
 was_touched = true
 play_sound(Sounds.STRAWMAN.TAP)
 play_touch_animation()


func _on_touch_screen_mouse_entered():
 touch_hovered = true


func _on_touch_screen_mouse_exited():
 touch_hovered = false
