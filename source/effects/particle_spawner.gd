extends Node2D


enum AreaType{
 CIRCLE, 
 RECTANGLE, 
}

@export var Particle: PackedScene
@export var enabled = true
@export var scroll_with_background: bool = false
@export var min_cooldown = 0.1
@export var max_cooldown = 0.5
@export var area_type = AreaType.CIRCLE
@export var min_spawn_radius = 0.0
@export var max_spawn_radius = 32.0
@export var spawn_rect = Vector2(0, 0)
@export var min_velocity = Vector2(0, 0)
@export var max_velocity = Vector2(0, 0)
@export var color: Color = Color.WHITE:
 set(value):
  color = value
  if particle_group != &"":
   for particle in get_tree().get_nodes_in_group(particle_group):
    particle.modulate = color
@export var particle_group: StringName = &""

var cooldown = randf_range(min_cooldown, max_cooldown):
 set(value):
  cooldown = max(0, value)

var cooldown_multiplier = 1.0
var velocity_multiplier = 1.0

var use_local_particles: bool = false

@onready var main = Game.main


func _ready() -> void :
 use_local_particles = Util.has_parent_in_group(self, "use_local_particles")


func _physics_process(delta):
 if not is_visible_in_tree() or not enabled:
  cooldown = max_cooldown * cooldown_multiplier
  return

 if cooldown > 0:
  cooldown -= delta
  return

 spawn_particle()
 cooldown = randf_range(min_cooldown, max_cooldown) * cooldown_multiplier


func spawn_particle() -> Node2D:
 var particle: Node2D = Particle.instantiate()
 var spawn_position = _get_spawn_position()

 if particle_group != &"":
  particle.add_to_group(particle_group)

 if not use_local_particles and Game.is_in_run():
  var layer_node: = get_canvas_layer_node()
  if layer_node != null and layer_node is not GameBG:
   layer_node.add_child(particle)
  else:
   main.background_particle_container.add_child(particle)

  if scroll_with_background:
   particle.add_to_group("bg_scroll_no_save")
   particle.add_to_group("bg_free_offscreen")
   main.background.add_scrolling_node(particle)
 else:
  owner.get_parent().add_child(particle)

 particle.global_position = spawn_position
 particle.velocity = Vector2(
   randf_range(min_velocity.x, max_velocity.x), 
   randf_range(min_velocity.y, max_velocity.y))
 particle.velocity *= velocity_multiplier
 particle.modulate = color

 return particle


func _get_spawn_position():
 if area_type == AreaType.CIRCLE:
  var spawn_offset = (Vector2.RIGHT * randf_range(
     min_spawn_radius, max_spawn_radius))
  spawn_offset = spawn_offset.rotated(randf_range(0, PI))
  var spawn_position = global_position + spawn_offset

  return spawn_position

 elif area_type == AreaType.RECTANGLE:
  var spawn_position = Vector2(
     randf_range(0, spawn_rect.x), 
     randf_range(0, spawn_rect.y))

  return spawn_position


func burst(cooldown_amount: = 1.0, velocity_amount: = 1.0, duration: = 1.0, ease_type: = Tween.EASE_OUT):
 cooldown_multiplier = cooldown_amount
 velocity_multiplier = velocity_amount

 var cooldown_tween = create_tween()
 cooldown_tween.set_ease(ease_type)
 cooldown_tween.tween_property(self, "cooldown_multiplier", 1.0, duration)

 var velocity_tween = create_tween()
 velocity_tween.set_ease(ease_type)
 velocity_tween.tween_property(self, "velocity_multiplier", 1.0, duration)


func toggle(cd):
 enabled = true
 await Game.timeout(cd)
 enabled = false
