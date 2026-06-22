extends Node2D


var velocity = Vector2(0, 0)
@onready var mote = $ColorRect


func _ready():
 mote.modulate = Color(1, 1, 1, 0)

 var appear_tween = create_tween()
 appear_tween.set_ease(Tween.EASE_OUT)
 appear_tween.tween_property(mote, "modulate", 
   Color(1, 1, 1, randf_range(0.15, 0.5)), randf_range(0.5, 2))

 await appear_tween.finished
 await Game.timeout(randf_range(0.5, 5))

 var disappear_tween = create_tween()
 disappear_tween.set_ease(Tween.EASE_IN)
 disappear_tween.tween_property(mote, "modulate", 
   Color(1, 1, 1, 0), randf_range(0.5, 2))

 await disappear_tween.finished
 queue_free()


func _physics_process(_delta):
 global_position += velocity
