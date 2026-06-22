class_name ArcingProjectile extends CharacterBody2D


signal impacted

enum LaunchDirection{
 LEFT, 
 RIGHT, 
}

@export var gravity: float = 800
@export var poof_color: String
@export var color_reference = Globals.COLORS
@export var look_at_direction: = true
@export var do_poof: = true
@export var parent_effect_to_group: StringName = &""

@export var impact_effect_scene: PackedScene = preload("res://source/effects/poofcloud.tscn")

var dest = Vector2.ZERO
var target = null
var free_on_impact = true
var is_launched = false
var added_rotation: float = 0.0
var angular_velocity: float = 0.0
var angular_deceleration: float = 0.0
var decelerate_to: float = 0.0
var launch_direction = LaunchDirection.LEFT


func _ready():
 hide()


func _physics_process(delta):
 velocity.y += gravity * delta
 move_and_collide(velocity * delta)

 if angular_deceleration != 0:
  angular_velocity = move_toward(angular_velocity, decelerate_to, angular_deceleration * delta)

 if look_at_direction:
  added_rotation += angular_velocity * delta
  look_at(global_position + velocity)
  rotation += added_rotation
 else:
  rotation += angular_velocity * delta


 if not visible:
  show()

 if not is_launched:
  return

 if global_position.y >= dest.y:
  if launch_direction == LaunchDirection.LEFT:
   if global_position.x <= dest.x:
    impact()

  elif launch_direction == LaunchDirection.RIGHT:
   if global_position.x >= dest.x:
    impact()


func calculate_arc_velocity(source_position, target_position, arc_height, arc_gravity):
 arc_height = - arc_height
 var arc_velocity = Vector2()
 var displacement = target_position - source_position

 if displacement.y > arc_height:
  var time_up = sqrt(-2 * arc_height / float(arc_gravity))
  var time_down = sqrt(2 * (displacement.y - arc_height) / float(arc_gravity))

  arc_velocity.y = - sqrt(-2 * gravity * arc_height)
  arc_velocity.x = displacement.x / float(time_up + time_down)

 return arc_velocity


func launch(starting_position, target_position, arc_height):
 global_position = starting_position
 dest = target_position

 if starting_position.x > target_position.x:
  launch_direction = LaunchDirection.LEFT
 else:
  launch_direction = LaunchDirection.RIGHT

 velocity = calculate_arc_velocity(global_position, target_position, arc_height, gravity)
 is_launched = true


func impact():
 if do_poof:
  impact_effect()

 emit_impact()

 if free_on_impact:
  get_parent().remove_child(self)
  queue_free()


func impact_effect(spawn_position = dest):
 var parent_to: Node = get_parent()
 if parent_effect_to_group != &"":
  parent_to = get_tree().get_first_node_in_group(parent_effect_to_group)

 if parent_to == null:
  return

 var effect = impact_effect_scene.instantiate()

 parent_to.add_child(effect)
 effect.global_position = spawn_position

 if poof_color != "":
  effect.modulate = Globals.COLORS[poof_color]


func kill():
 impact_effect(global_position)
 get_parent().remove_child(self)
 queue_free()


func emit_impact():
 impacted.emit()
