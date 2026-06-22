extends Control

const TURN_TIME: = 120000

var time_scale: int = 1:
 set(value):
  time_scale = value
  update()
var timer: GameTimer
var enabled: = false
var appearing: = false
var disappear_timer: float = 0.0
var clone_label: Label

@onready var label: Label = %TimeLabel
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var position_base: Control = %PositionBase


func _ready() -> void :
 set_process(false)
 hide()


func _process(delta: float) -> void :
 if timer == null:
  return

 if disappear_timer > 0.0:
  disappear_timer -= delta

 if not timer.is_active and not appearing and disappear_timer <= 0.0:
  anim_player.play_reversible_appear_disappear(false)
 else:
  anim_player.play_reversible_appear_disappear(true)

 if timer.is_active and Game.main.options_menu.is_doing_anything() and Game.main.options_menu.has_reset_position:
  if clone_label == null:
   clone_label = CopyUtil.instantiate_clone(label)
   CopyUtil.copy_full(label, clone_label)
   Game.main.above_menu_wall.add_child(clone_label)

  var options_menu: = Game.main.options_menu
  var base_global_rect: = position_base.get_global_rect()
  if options_menu.top_marker.global_position.y < base_global_rect.end.y:
   label.position.y = options_menu.top_marker.global_position.y - base_global_rect.end.y
  else:
   label.position.y = 0

  clone_label.modulate = modulate
  CopyUtil.copy_transform(label, clone_label)
 else:
  if clone_label != null:
   clone_label.queue_free()
   clone_label = null

  label.position.y = 0

 if not timer.is_running():
  if appearing:
   label.text = "02:00:00"

  return

 var remaining_ms: = get_remaining_time()
 label.text = StringManager.format_time(remaining_ms, StringManager.MMSSTT)

 if clone_label != null:
  CopyUtil.copy_light(label, clone_label)

 if remaining_ms <= 0:
  disappear_timer = 1.0
  Game.main.force_end_player_turn(false)


func get_remaining_time() -> int:
 if timer == null:
  return 0
 else:
  return timer.get_remaining_time(TURN_TIME, time_scale)


func enable():
 enabled = true
 timer = GameTimer.new()
 timer.started.connect( func(): time_scale = 1)
 set_process(true)
 update()
 show()


func update():
 match time_scale:
  1:
   modulate = Color(1, 1, 1)
  2:
   modulate = Color(1, 0.5, 0.5)
  2.5:
   modulate = Color(1, 0.4, 0.4)
  3:
   modulate = Color(1, 0.3, 0.3)
  4:
   modulate = Color(1, 0.15, 0.15)
  5.5:
   modulate = Color(1, 0, 0)
