extends "res://source/effects/static_particle.gd"


signal hit


var frames = {
 0: {
  scale_offset_position = Vector2(0, 26), 
  sprite_offset = Vector2(3, -29), 
 }, 
 1: {
  scale_offset_position = Vector2(0, 26), 
  sprite_offset = Vector2(0, -33), 
 }, 
 2: {
  scale_offset_position = Vector2(0, 24), 
  sprite_offset = Vector2(-4, -25), 
 }, 
 3: {
  scale_offset_position = Vector2(0, 24), 
  sprite_offset = Vector2(0, -32), 
 }, 
 4: {
  scale_offset_position = Vector2(0, 24), 
  sprite_offset = Vector2(-2, -36), 
 }, 
}


func set_frame(frame: int, text_frame: int) -> void :
 %Sprite.frame = frame
 %Text.frame_coords = Vector2i(frame, text_frame)

 %PositionOffset.position = frames[frame].scale_offset_position * -1
 %ScaleOffset.position = frames[frame].scale_offset_position
 %Sprite.offset = frames[frame].sprite_offset
 %Text.offset = %Sprite.offset


func _on_anim_player_event_emitted(event_name: String) -> void :
 if event_name == "hit":
  hit.emit()
