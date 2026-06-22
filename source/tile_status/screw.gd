class_name ScrewStatus extends Status

var turns: int = 1


func get_tooltip_context():
 return {screw_turns = turns}


func apply(_turns):
 tile.set_face(" ", false)
 tile.remove_face_statuses()

 if _turns == null:
  set_turns(1)
 else:
  set_turns(_turns)


func update_status_visual() -> void :
 tile.tile_sprite.screw.visible = true
 tile.tile_sprite.screw.frame = 1 if turns == 0 else 0


func clear():
 tile.tile_sprite.screw.visible = false
 tile.tile_sprite.set_hole(false)


func set_turns(_turns: int) -> void :
 turns = maxi(0, _turns)
 update_status_visual()


func preventing_dragging() -> bool:
 return not is_space()


func handles_click() -> bool:
 return not is_space()


func handle_click() -> bool:
 tile.animation.play("shake")
 return true


func is_space() -> bool:
 return turns == 0


func is_always_playable() -> bool:
 return true


func get_save_data():
 return turns


func load_save_data(_turns):
 set_turns(_turns)
