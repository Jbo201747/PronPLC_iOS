extends Node2D


const MAX_SATURATION = 0.5
const MAX_PARRY = 10.0

@onready var sprite = $Sprite


var letters_left = 8:
 set(value):
  letters_left = clamp(value, 0, MAX_PARRY)
  sprite.self_modulate.s = letters_left * MAX_SATURATION / MAX_PARRY
