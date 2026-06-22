extends Node2D


var fishing_minigame = null
var is_despawning = false
var lifetime = 1
var is_small = false

var h_speed = 0
var v_speed = 0
var h_acceleration = 1
var v_acceleration = 1

@onready var anim_player = $AnimPlayer


func _ready():
 if randi_range(0, 2) == 0:
  is_small = true
  anim_player.play("appear_small")


func _physics_process(delta):
 var sink_speed = 0

 if fishing_minigame != null:
  sink_speed = fishing_minigame.sink_speed

 position.x -= h_speed * h_acceleration * delta
 position.y -= ((v_speed * v_acceleration) + sink_speed) * delta

 if h_acceleration > 0:
  h_acceleration = max(0, h_acceleration - 1 * delta)

 if v_acceleration > 0:
  v_acceleration = max(0.2, v_acceleration - 0.25 * delta)

 lifetime -= 1 * delta

 if lifetime <= 0 and not is_despawning:
  is_despawning = true

  if is_small:
   anim_player.queue("disappear_small")
  else:
   anim_player.queue("disappear")


func spawn(speed):
 if speed == null:
  h_speed = randf_range(-80, 80)
 else:
  h_speed = speed

 v_speed = randf_range(10, 60)
 lifetime = randf_range(0.4, 2)
