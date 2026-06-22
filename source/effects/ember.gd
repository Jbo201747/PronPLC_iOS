extends Node2D


@export var secondary_color = Color(1499027967)

var intensity = 0.0
var intensity_mutable = true

@onready var time = randf_range(0, 100)
@onready var max_life = randf_range(1, 3)
@onready var y_speed = randf_range(3, 8)

@onready var sprite = $Sprite
@onready var anim_player = $AnimPlayer


func _ready():
 var soot_tween = create_tween()
 soot_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 soot_tween.tween_property(sprite, "modulate", secondary_color, max_life)
 await soot_tween.finished

 var dissolve_tween = create_tween()
 dissolve_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 dissolve_tween.tween_property(sprite, "modulate", Color(1499027712), 1)
 await dissolve_tween.finished

 queue_free()


func _physics_process(delta):
 time += delta

 if intensity <= 0:
  if randf() <= 0.05 and intensity_mutable:
   intensity_mutable = false

   var new_intensity = randf_range(0, 1)
   var tween = create_tween()

   tween.set_ease(Tween.EASE_IN_OUT)
   tween.tween_property(self, "intensity", new_intensity, 1)

   await tween.finished
   intensity_mutable = true

 var x_movement = (sin(time) - 0.5) * 15 * intensity

 sprite.position.x = x_movement
 sprite.position.y -= y_speed * delta
