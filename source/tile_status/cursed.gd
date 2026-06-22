extends Status


const MAX_PARTICLE_DELAY = 10
const MIN_PARTICLE_DELAY = 2
var particle_delay = randf_range(MIN_PARTICLE_DELAY, MAX_PARTICLE_DELAY)

var ember_resource = preload("res://source/effects/cursed_ember.tscn")


func _process(delta):
 if not tile.is_visible_in_tree():
  return

 particle_delay -= delta

 if particle_delay <= 0:
  var ember = ember_resource.instantiate()
  particle_delay = randf_range(MIN_PARTICLE_DELAY, MAX_PARTICLE_DELAY)

  Game.get_particle_target(tile).add_child(ember)
  ember.global_position = tile.global_position + Vector2(
    randi_range(0, 10) * [1, -1].pick_random(), 
    randi_range(0, 10) * [1, -1].pick_random())


func get_sprite_animation():
 return "cursed"
