@tool
extends Node2D


var value = 0
var is_player = false

@onready var anim_player = $AnimPlayer
@onready var sprite = $Sprite
@onready var label = $Sprite / Label
@onready var shadow_label = $Sprite / Label / ShadowLabel


func appear(amount, _is_player):
 value = amount
 is_player = _is_player

 if is_player:
  add_to_group("player_popup")
 else:
  add_to_group("enemy_popup")

 if amount <= 0:
  sprite.frame = 1
  label.hide()
 else:
  label.text = str(amount)
  shadow_label.text = label.text

 if is_player:
  anim_player.play_advance("send_right")
 else:
  anim_player.play_advance("send_left")

 await anim_player.animation_finished
 get_parent().remove_child(self)
 queue_free()
