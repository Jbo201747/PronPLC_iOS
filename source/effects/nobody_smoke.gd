class_name NobodySmoke extends Node2D


const EXTRA_VELOCITY_DECEL = 0.5


var amplitude: float = 8.0


var frequency: float = 5.0

var time: float = 0.0

var velocity: Vector2 = Vector2.ZERO

var extra_velocity: Vector2 = Vector2.ZERO

@onready var wave_offset: Node2D = %WaveOffset
@onready var anim_player: AnimPlayer = %AnimPlayer


func _physics_process(delta: float) -> void :
 time += delta

 wave_offset.position.x = sin((time / frequency) * TAU) * amplitude
 position += velocity * delta

 position += extra_velocity * delta
 extra_velocity.limit_length(extra_velocity.length() - EXTRA_VELOCITY_DECEL * delta)

 if global_position.y < -32:
  queue_free()
