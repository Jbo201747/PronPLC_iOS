extends "res://source/effects/ember.gd"


func _ready():
 max_life *= 0.5

 sprite.frame = randi_range(0, 1)

 await Game.timeout(max_life)

 var dissolve_tween = create_tween()
 dissolve_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 dissolve_tween.tween_property(sprite, "modulate", Color(4294967040), 1)
 await dissolve_tween.finished

 queue_free()
