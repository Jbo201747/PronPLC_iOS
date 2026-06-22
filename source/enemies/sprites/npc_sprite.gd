@tool
class_name NPCSprite extends BattleUnitSprite


signal start_respawning
signal respawned
signal attack_finished
signal state_changed

@export var walk_radius = 12.0

const ATTACK_FRAMES = [2, 3, 4]
const FLINCH_FRAMES = [6, 7, 8]

var speed_multiplier = 1
var is_tweening: = false
var is_idle: = false:
 set(value):
  if is_idle != value:
   is_idle = value
   state_changed.emit()
var is_still: = false
var is_dead: = false:
 set(value):
  if is_dead != value:
   is_dead = value
   state_changed.emit()
var is_respawning: = false:
 set(value):
  if is_respawning != value:
   is_respawning = value
   state_changed.emit()
var is_attacking: = false
var is_wandering: = false
var tween: Tween

@onready var sprite = $WanderOffset / PaceOffset / Sprite
@onready var wander_offset = $WanderOffset
@onready var pace_offset: Node2D = %PaceOffset


func _process(_delta):
 if is_idle and not is_tweening:
  walk_around()


func walk_around():
 var dest = (Vector2.RIGHT * randf_range(0, walk_radius))
 dest = dest.rotated(randf_range(0, PI))
 dest.y *= 0.5

 is_wandering = true
 await walk_to(wander_offset, dest)
 is_wandering = false


func walk_to(object, dest, duration: float = -1):
 var distance = object.position.distance_to(dest)

 if duration == -1:
  duration = (distance / walk_radius) * (3 + 0.5 * speed_multiplier)

 if is_tweening:
  if tween and tween.is_running():
   tween.kill()
   tween.finished.emit()

 is_tweening = true

 tween = create_tween()
 tween.set_ease(Tween.EASE_IN_OUT)
 tween.set_trans(Tween.TRANS_QUAD)
 tween.tween_property(object, "position", dest, duration)

 await tween.finished
 is_tweening = false


func start_idle(desync_by: float = 0.0, account_for_speed_scale: bool = false):
 is_still = false
 anim_player.speed_scale = 1 - 0.1 * speed_multiplier
 anim_player.play("when_u_walkin")
 if desync_by > 0.0:
  if account_for_speed_scale:
   desync_by /= anim_player.speed_scale
  anim_player.advance(desync_by)
 is_idle = true


func halt_idle(instant = true):
 is_idle = false

 if not instant:
  if anim_player.is_playing() and anim_player.current_animation == "when_u_walkin":
   await animation_looped
  anim_player.stop(true)
 else:
  anim_player.stop()

 if tween:
  tween.kill()
  tween.finished.emit()

 anim_player.speed_scale = 1
 is_tweening = false


func stand_still(instant: = false) -> void :
 is_idle = false
 is_still = true

 if not instant:
  if is_tweening:
   if is_wandering:
    tween.kill()
    tween.finished.emit()
   else:
    await tween.finished

  if wander_offset.position != Vector2.ZERO:
   await walk_to(wander_offset, Vector2.ZERO, 0.4)

  if anim_player.is_playing() and anim_player.current_animation == "when_u_walkin":
   await animation_looped

 anim_player.speed_scale = 1

 var pace_tween: = create_tween()
 pace_tween.set_ease(Tween.EASE_OUT)
 pace_tween.tween_property(pace_offset, "position", Vector2(-4, 0), 0.4)
 anim_player.play("stand")


func attack(still_after: = false, pitch: float = 1.0):
 is_attacking = true
 anim_player.speed_scale = 3
 await halt_idle(false)

 if sprite.frame == 0:
  anim_player.play("attack")
 else:
  anim_player.play("attack_alt")

 await hit

 play_sound(Sounds.NPC.ATTACK, pitch)

 await anim_player.animation_finished

 if sprite.frame == 0:
  start_idle()
 else:
  start_idle(0.6, true)

 if still_after:
  await stand_still()

 is_attacking = false
 attack_finished.emit()


func flinch():
 if not is_still:
  halt_idle()
 anim_player.play("flinch")
 await anim_player.animation_finished

 if not is_still:
  start_idle()


func alternate_walk_frame():
 if sprite.frame == 0:
  sprite.frame = 1
 if sprite.frame == 1:
  sprite.frame = 0


func randomize_attack_frame():
 sprite.frame = ATTACK_FRAMES.pick_random()


func randomize_flinch_frame():
 sprite.frame = FLINCH_FRAMES.pick_random()


func respawn(start_still: = false):
 speed_multiplier = randf_range(0, 1)

 if start_still:
  wander_offset.position = Vector2.ZERO

 anim_player.play("walk_in")
 await pend_event("walk_in")
 is_respawning = true
 start_respawning.emit()
 await anim_player.animation_finished

 if start_still:
  stand_still(true)
 else:
  start_idle()

 is_respawning = false
 is_dead = false
 respawned.emit()
