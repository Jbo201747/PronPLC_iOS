extends "res://source/ui/icon_button.gd"


func _ready() -> void :
 Game.difficulty_changed.connect(update_frame)
 Game.main.game_state_updated.connect(update)


func update() -> void :
 disabled = not Game.main.can_toggle_pause(false)
 action_glyph.disabled = disabled


func update_frame() -> void :
 if Game.active_daily:
  %Sprite.texture = preload("res://arte/ui/floppy_disks_b_daily.png")
 else:
  %Sprite.texture = preload("res://arte/ui/floppy_disks_b.png")

 %Sprite.frame = Game.difficulty
