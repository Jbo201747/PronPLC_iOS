@tool
extends "res://source/enemies/sprites/strawman_sprite.gd"


var last_xd = -1
var xd_frames = [1, 2, 3]
var taps_needed: int = 100
var times_tapped: int = 0


@onready var face = $Sprite / FaceOffset / Face


func _init():
 super._init()
 touch_anim = "rand_xd"


func _ready() -> void :
 super._ready()
 set_physics_process(false)


func update_blush(_delta: float) -> void :
 horniness = 0


func play_touch_animation() -> void :
 super.play_touch_animation()
 _pick_random_xd()


func _pick_random_xd():
 var new_xd_frames = xd_frames.duplicate()
 new_xd_frames.erase(last_xd)

 face.frame = new_xd_frames.pick_random()
 last_xd = face.frame


func _touch():
 var pee: = false
 if Game.is_in_run():
  times_tapped += 1
  if times_tapped >= taps_needed:
   pee = true
   taps_needed *= 10
   times_tapped = 0
   anim_player.play("pee")

 if not pee:
  super._touch()
