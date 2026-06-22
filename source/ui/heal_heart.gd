@tool
extends "res://source/ui/damage_star.gd"


func appear(amount, _is_player):
 value = amount

 sprite.frame = 2
 label.text = str(amount)
 shadow_label.text = label.text

 anim_player.play_advance("heart_balloon")

 await anim_player.animation_finished
 get_parent().remove_child(self)
 queue_free()
