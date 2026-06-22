@tool
extends BattleUnitSprite

var base_offset = null
var twitch_timer = 2
var skip_next_alt_idle_roll = true
var is_twitching = false
var is_critical: Callable

@onready var snowball_sprite = $Sprite


func _ready():
 super._ready()
 if Engine.is_editor_hint():
  return

 event_emitted.connect(rng_alt_idle)
 anim_player.animation_finished.connect(_on_anim_player_animation_finished)



func _physics_process(_delta):
 if Engine.is_editor_hint():
  return

 if is_twitching:
  if twitch_timer == 0:
   is_twitching = false
   snowball_sprite.offset = base_offset
  else:
   twitch_timer -= 1

 if anim_player.current_animation not in ["idle", "idle_wipe"]:
  return

 var odds = 500
 if is_critical.is_valid() and is_critical.call():
  odds = 200

 var roll = randf_range(0, odds)

 if roll < 3 and not is_twitching:
  twitch()


func twitch():
 is_twitching = true
 base_offset = snowball_sprite.offset
 var twitch_offset = [1, 2, -1, -2].pick_random()
 snowball_sprite.offset.x += twitch_offset
 twitch_timer = 1




func rng_alt_idle(sprite_event):
 if sprite_event != "idle_finished":
  return

 if skip_next_alt_idle_roll:
  skip_next_alt_idle_roll = false
  return

 var odds = 50
 if is_critical.is_valid() and is_critical.call():
  odds = 20

 var wipe = randi_range(1, odds)

 if wipe == 1:
  anim_player.play("idle_wipe")

  if not is_critical.is_valid() or not is_critical.call():
   skip_next_alt_idle_roll = true


func _on_anim_player_animation_finished(anim_name):
 if anim_name in ["die", "drag", "blow"]:
  return

 anim_player.play("idle")
 skip_next_alt_idle_roll = true
