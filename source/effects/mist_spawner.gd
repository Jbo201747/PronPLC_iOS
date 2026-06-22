extends Node2D


const MAX_COOLDOWN = 18.0

@export var cooldown_multiplier = 1.0
@export var cooldown_variance = 1.5
@export var hide_effects = false
@export var group = "freezer_mist"

var is_gold = false
var cooldown = MAX_COOLDOWN * cooldown_multiplier
var Poofcloud = preload("res://source/effects/mist.tscn")

var use_local_particles: bool = false

@onready var main = Game.main


func _ready() -> void :
 use_local_particles = Util.has_parent_in_group(self, "use_local_particles")


func _process(delta):
 if not is_visible():
  cooldown = MAX_COOLDOWN * cooldown_multiplier
  return

 if cooldown > 0:
  cooldown -= 1 * 60 * delta
  return

 spawn_mist()

 var variance = randf_range(MAX_COOLDOWN / cooldown_variance, MAX_COOLDOWN)
 cooldown = variance * cooldown_multiplier


func spawn_mist():
 var poofcloud = Poofcloud.instantiate()

 var color = Globals.COLORS.ICE if not is_gold else Globals.COLORS.PISS_ICE



 var direction = randf_range(0, PI)
 var spawn_offset = (Vector2.RIGHT * randf_range(8, 16)).rotated(direction)
 var spawn_position = global_position + spawn_offset
 var velocity = (Vector2.RIGHT * randf_range(0.25, 0.5)).rotated(direction)




 if group != "":
  poofcloud.add_to_group(group)

 if not use_local_particles and Game.is_in_run():
  main.add_child(poofcloud)
 else:
  poofcloud.z_index -= 1
  owner.get_parent().add_child(poofcloud)

 poofcloud.global_position = spawn_position
 poofcloud.modulate = color

 poofcloud.z_index = 4
 poofcloud.velocity = velocity

 if hide_effects:
  poofcloud.hide()
