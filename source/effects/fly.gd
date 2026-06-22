extends Node2D


const MAX_SPEED = Vector2(100, 100)
const ACCELERATION = 8

var target_position = Vector2(227, 122)
var velocity = Vector2(0, 0):
 set(value):
  velocity = value.clamp( - MAX_SPEED, MAX_SPEED)


func _physics_process(delta):
 var distance = target_position - global_position

 velocity += distance.normalized() * 8
 velocity = velocity.limit_length(200)

 global_position += velocity * delta



func target_and_die(dest, time):
 target_position = dest
 await Game.timeout(time)
 queue_free()
