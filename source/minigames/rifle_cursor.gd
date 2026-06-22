extends Node2D


const BULLET_HOLE: PackedScene = preload("res://source/effects/bullet_hole.tscn")


@export var minigame: FiringMinigame
@onready var hitbox = $Hitbox
@onready var anim_player = $AnimPlayer


func _process(_delta):
 if not InputManager.is_mouse_mode():
  global_position += InputManager.get_any_movement_vector() * 6.0
  var rect: Rect2 = get_parent().get_global_rect()
  global_position = global_position.clamp(rect.position, rect.position + rect.size)
 else:
  global_position = InputManager.get_mouse_position()


func _input(event):
 if event.is_action_pressed("primary_button"):
  shoot()


func shoot():
 var rect: Rect2 = get_parent().get_global_rect()
 if not rect.has_point(global_position):
  return

 if minigame != null:
  var pos: = minigame.background.make_canvas_position_local(global_position)
  var bullet_hole = BULLET_HOLE.instantiate()
  bullet_hole.position = pos
  minigame.sub_viewport.add_child(bullet_hole)

 Game.screenshake(16, 0.2)
 AudioManager.play_sound(Sounds.SPELLS.GUNSHOT)
 if anim_player.current_animation == "fire" and anim_player.is_playing():
  anim_player.seek(0)
 else:
  anim_player.play("fire")

 var hurtboxes = hitbox.get_overlapping_areas()

 for hurtbox in hurtboxes:
  if hurtbox.is_in_group("fish"):
   var fish = hurtbox.owner
   if fish.visible and not fish.tile.is_indestructible():
    fish.shoot()
