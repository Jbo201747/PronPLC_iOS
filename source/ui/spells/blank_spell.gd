class_name BlankSpell extends Node2D


@onready var anim_player: AnimationPlayer = %AnimationPlayer


func disappear(instant: = false):
 await anim_player.play_until_finished("disappear", instant)


func appear(instant: = false):
 await anim_player.play_until_finished("appear", instant)
