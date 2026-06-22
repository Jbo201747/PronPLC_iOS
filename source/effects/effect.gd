extends AnimatedSprite2D


func _ready():
 play("default")
 await animation_looped
 get_parent().remove_child(self)
 queue_free()


func color_fade(color, duration):
 var tween = create_tween()
 tween.set_trans(Tween.TRANS_QUART)
 tween.set_ease(Tween.EASE_IN_OUT)
 tween.tween_property(self, "modulate", color, duration)
