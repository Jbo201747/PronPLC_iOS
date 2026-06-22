@tool
extends BattleUnitSprite


const MIN_IDLE_DELAY = 1.0
const MAX_IDLE_DELAY = 8.0

const MIN_IDLE_DURATION = 0.3
const MAX_IDLE_DURATION = 1.4


var idle_delay: float = randf_range(MIN_IDLE_DELAY, MAX_IDLE_DELAY)
var idle_duration: float = 0.0

var jabber_fx: AudioManagerSingleton.SoundPlayback

var stopping_chattering: bool = false


func _physics_process(delta: float) -> void :
 if Engine.is_editor_hint():
  return

 if stopping_chattering:
  return

 if anim_player.assigned_animation == "chatter_a":
  idle_duration -= delta

  if idle_duration <= 0.0:
   stop_chattering()
  elif jabber_fx == null or not jabber_fx.is_valid:
   jabber_fx = play_sound(Sounds.PROLE_SERVICE.JABBER)
 elif anim_player.assigned_animation != "idle":
  if jabber_fx != null and jabber_fx.is_valid:
   jabber_fx.stop()

  return
 else:
  idle_delay -= delta
  if idle_delay <= 0.0:
   idle_delay = randf_range(MIN_IDLE_DELAY, MAX_IDLE_DELAY)
   idle_duration = randf_range(MIN_IDLE_DURATION, MAX_IDLE_DURATION)
   anim_player.play("chatter_a")


func stop_chattering() -> void :
 stopping_chattering = true

 if jabber_fx != null and jabber_fx.is_valid:
  await jabber_fx.finished

 if anim_player.current_animation == "chatter_a":
  await pend_event("loop_break")
  anim_player.play_advance("RESET")
  anim_player.play_advance("idle")

 stopping_chattering = false
