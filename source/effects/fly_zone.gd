extends CollisionShape2D


const FLY = preload("res://source/effects/fly.tscn")
var flies = {}


func _process(delta):
 for fly in flies:
  _process_fly(delta, fly)


func _exit_tree() -> void :
 for fly in flies:
  if is_instance_valid(fly) and not fly.is_queued_for_deletion():
   fly.queue_free()


func spawn_flies(amount):
 for i in range(amount):
  var fly = FLY.instantiate()
  var spawn_offset = Vector2(randf_range(-16, 16), randf_range(-16, 16))

  get_tree().current_scene.add_child.call_deferred(fly)
  fly.tree_exited.connect( func(): flies.erase(fly))
  flies[fly] = 0
  fly.global_position = global_position + spawn_offset


func _process_fly(delta, fly):
 if flies[fly] > 0:
  flies[fly] -= delta
  return

 _retarget_fly(fly)


func _retarget_fly(fly):
 var rand_position = Vector2(
   randf_range(0, shape.size.x), 
   randf_range(0, shape.size.y))
 rand_position -= shape.size / 2.0
 rand_position += global_position
 fly.target_position = rand_position

 flies[fly] = randf_range(2, 3)
