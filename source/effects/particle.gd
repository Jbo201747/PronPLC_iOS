extends Node2D


var velocity = Vector2(0, 0)


func _ready():
 await $AnimPlayer.animation_finished
 get_parent().remove_child(self)
 queue_free()


func _physics_process(_delta):
 if velocity.is_equal_approx(Vector2(0, 0)):
  return

 global_position += velocity
