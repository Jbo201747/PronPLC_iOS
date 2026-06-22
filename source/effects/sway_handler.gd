class_name SwayHandler extends Node2D


var prev_global_position: Vector2 = Vector2.INF
var sway_velocity: float = 0.0


@export var maximum_sway: float = 35.0

@export var decay: float = 0.2

@export var acceleration: float = 0.1

@export var friction: float = 0.7




@export var direct_from_position_multiplier: float = -1.0

@export var position_exponent: bool = false

@export var disabled: = false:
 set(value):
  disabled = value
  reset_position()


func _physics_process(_delta: float) -> void :
 if disabled:
  return

 if prev_global_position == Vector2.INF:
  prev_global_position = global_position
  return

 var position_change: = global_position.x - prev_global_position.x

 if direct_from_position_multiplier >= 0.0:
  if abs(position_change) != 0.0:
   var target_rotation: = position_change * direct_from_position_multiplier
   if position_exponent:
    target_rotation = abs(position_change) ** direct_from_position_multiplier
    target_rotation *= sign(position_change)

   rotation_degrees = clampf(target_rotation, - maximum_sway, maximum_sway)
  elif not is_zero_approx(rotation_degrees):
   rotation_degrees = lerpf(rotation_degrees, 0.0, decay)
 else:
  var target_sway: float = 0.0
  if abs(position_change) >= 2.0:
   target_sway = signf(position_change) * maximum_sway

  var difference: = target_sway - rotation_degrees
  if target_sway == 0.0:
   sway_velocity = sway_velocity + difference * decay
  else:
   sway_velocity = sway_velocity + difference * acceleration

  sway_velocity *= friction
  rotation_degrees += sway_velocity

 prev_global_position = global_position


func reset_position() -> void :
 prev_global_position = Vector2.INF
