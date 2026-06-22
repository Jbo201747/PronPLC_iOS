@tool
extends Node2D


const CENTER = 64
const UPPER_BOUNDS = -32
const LOWER_BOUNDS = 224

var vertical_speed = 0
var is_removing = false

@onready var rings = [ %RingA, %RingB, %RingC]
@onready var outlines = [ %OutlineA, %OutlineB, %OutlineC]


func _ready() -> void :
 do_copying()


func _process(_delta: float) -> void :
 do_copying()

 if not Engine.is_editor_hint():
  if position.y <= UPPER_BOUNDS and not is_removing:
   queue_free()


func _physics_process(delta):
 if not Engine.is_editor_hint():
  position.y += vertical_speed * delta


func spawn(x_offset = 0, y_offset = 0):
 position = Vector2(CENTER, LOWER_BOUNDS) + Vector2(x_offset, y_offset)


func disappear():
 is_removing = true
 AudioManager.play_sound(Sounds.FISHER.FISH_DASH, 1.0, 1.0, "SoundLowpass")
 %AnimPlayer.play("disappear")
 await %AnimPlayer.animation_finished
 queue_free()


func get_boost_multiplier():
 return max(192.0 - position.y, 0) / 192.0


func do_copying() -> void :
 for i in range(rings.size()):
  var ring = rings[i]
  var outline = outlines[i]

  CopyUtil.copy_transform(ring, outline)
  CopyUtil.copy_sprite_frame(ring, outline)
  CopyUtil.copy_visibility(ring, outline)
