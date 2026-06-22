class_name NobodyParticleSpawner extends Node2D



const VELOCITY_FACTOR = Vector2(2.0, 2.0)

@export var particle_scene: PackedScene


@export var cooldown_min: float = 0.5


@export var cooldown_max: float = 1.5


@export var angle_variance: float = 35.0


@export var minimum_angle_variance: float = -1.0


@export var velocity: float = 12.0


@export var amplitude: float = 8.0


@export var frequency: float = 5.0

@export var phase_switch_cooldown_min: float = 5.0
@export var phase_switch_cooldown_max: float = 10.0

@export var smoke_anim: StringName = &"main_smoke"

@export var position_relative_to: Node2D

var phase_switch_cooldown: float = 0.0
var cooldown: float = 0.0

var phase: int = 1

var accumulated_delta: float = 0.0

var last_relative_position: Vector2 = Vector2.INF

var last_velocities: Array[Vector2] = []


func _ready() -> void :
 phase = -1 if Game.random.randi() % 2 == 0 else 1
 phase_switch_cooldown = Game.random.randf_range(phase_switch_cooldown_min, phase_switch_cooldown_max)
 cooldown = Game.random.randf_range(cooldown_min, cooldown_max)

 last_velocities.resize(10)
 for i in 10:
  last_velocities[i] = Vector2.ZERO


func _physics_process(delta: float) -> void :
 var target_node: SubViewport = get_tree().get_first_node_in_group("nobody_particle_target")
 if target_node == null:
  return

 var target_sprite: Sprite2D = get_tree().get_first_node_in_group("nobody_smoke_viewport_sprite")
 if target_sprite == null:
  return

 if not is_visible_in_tree():
  last_relative_position = Vector2.INF
  return

 var last_average_vel_was_zero: bool = true
 for v in last_velocities:
  if v != Vector2.ZERO:
   last_average_vel_was_zero = false

 var relative_position: Vector2 = global_position
 if position_relative_to != null:
  relative_position = global_position - position_relative_to.global_position

 var spawner_velocity: Vector2 = Vector2.ZERO
 if last_relative_position != Vector2.INF:
  var current_velocity: = relative_position - last_relative_position

  if last_average_vel_was_zero:
   for i in 10:
    last_velocities[i] = current_velocity
  else:
   last_velocities.insert(0, current_velocity)
   last_velocities.resize(10)

 for v in last_velocities:
  spawner_velocity += v

 spawner_velocity /= 10

 var spawner_velocity_length: float = spawner_velocity.length()

 last_relative_position = relative_position

 accumulated_delta += delta * (1.0 + spawner_velocity_length * 3.0)

 while accumulated_delta >= cooldown:
  accumulated_delta -= cooldown
  phase_switch_cooldown -= cooldown

  cooldown = Game.random.randf_range(cooldown_min, cooldown_max)
  if delta < 0.0:
   cooldown -= delta
   phase_switch_cooldown -= delta

  var particle: NobodySmoke = particle_scene.instantiate()
  target_node.add_child(particle)
  particle.position = target_node.get_parent().to_local(global_position) - target_sprite.position

  var angle_deg: float = 0.0
  if minimum_angle_variance != -1.0:
   var left_right: int = -1 if Game.random.randi() % 2 == 0 else 1
   angle_deg = Game.random.randf_range(minimum_angle_variance / 2.0, angle_variance / 2.0) * left_right
  else:
   angle_deg = Game.random.randf_range( - angle_variance / 2.0, angle_variance / 2.0)

  var direction: = Vector2.UP.rotated(deg_to_rad(angle_deg))
  particle.velocity = direction * velocity
  particle.amplitude = amplitude * phase
  particle.frequency = frequency
  particle.extra_velocity = spawner_velocity * VELOCITY_FACTOR

  particle.extra_velocity.y = min(particle.extra_velocity.y, 0.0)
  particle.anim_player.play_advance(smoke_anim)

  if accumulated_delta > 0.0:
   particle.anim_player.advance(accumulated_delta)
   particle._physics_process(accumulated_delta)

  if phase_switch_cooldown <= 0.0:
   phase_switch_cooldown += Game.random.randf_range(phase_switch_cooldown_min, phase_switch_cooldown_max)
   phase = - phase
