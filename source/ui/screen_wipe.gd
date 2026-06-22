class_name ScreenWipe extends NinePatchRect


signal screen_covered


@onready var anim_player = $AnimationPlayer

@export var covered = false:
 set(value):
  screen_covered.emit()


func cover() -> void :
 anim_player.play("screen_covered")
 anim_player.advance(0)


func uncover() -> void :
 anim_player.play("RESET")
 anim_player.advance(0)


func wipe_in():
 anim_player.seek(0.0)
 anim_player.play_section_with_markers("screen_wipe", "wipe_in_start", "wipe_in_end")
 anim_player.advance(0)
 await anim_player.animation_finished


func wipe_out():
 anim_player.play_section_with_markers("screen_wipe", "wipe_out_start", "wipe_out_end")
 anim_player.advance(0)
 await anim_player.animation_finished


func wipe():
 anim_player.play("screen_wipe")
 anim_player.advance(0)
 await anim_player.animation_finished
