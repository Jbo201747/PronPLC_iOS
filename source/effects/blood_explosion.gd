extends Node2D


func _ready():
 await $Sprite2D / AnimPlayer.animation_finished
 get_parent().remove_child(self)
 queue_free()


func color_fade(color, duration):
 var tween = create_tween()
 tween.set_trans(Tween.TRANS_QUART)
 tween.set_ease(Tween.EASE_IN_OUT)
 tween.tween_property(self, "modulate", color, duration)
