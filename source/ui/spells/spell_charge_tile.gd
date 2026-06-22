@tool
class_name SpellChargeTile extends Node2D


signal rerolled_face

var arcing_projectile_scene = preload("res://source/effects/arcing_projectile.tscn")

var charged: = false

@onready var charge_face = %ChargeFace
@onready var anim_player: AnimationPlayer = $AnimPlayer


func set_face(letter):
 charge_face.face = letter


func set_charged(_charged: bool) -> void :
 charged = _charged
 if charged:
  anim_player.play("charge")
 else:
  anim_player.play("discharge")

 anim_player.advance(anim_player.current_animation_length)


func charge():
 charged = true
 anim_player.play("charge")


func discharge():
 charged = false
 anim_player.play("discharge")


func reroll(new_face):
 anim_player.play("reroll")

 await rerolled_face
 set_face(new_face)


func is_anim_busy():
 return anim_player.is_playing() and anim_player.current_animation not in ["flash_fast", "flash_slow"]


func flash(flash_anim: String):
 if not is_anim_busy():
  anim_player.play(flash_anim)


func stop_flashing():
 if anim_player.current_animation in ["flash_fast", "flash_slow"]:
  anim_player.stop()
  self_modulate = Color(1, 1, 1)


func remove():
 var start_position = global_position
 var arcing_projectile = arcing_projectile_scene.instantiate()
 Game.main.add_child(arcing_projectile)

 reparent(arcing_projectile)

 arcing_projectile.look_at_direction = false
 arcing_projectile.do_poof = false
 arcing_projectile.gravity = 500

 position = Vector2(0, 0)

 arcing_projectile.launch(
  start_position, 
  start_position + Vector2(32, 64), 
  32, 
 )

 anim_player.play("spin")
