@tool
extends BattleUnitSprite

const MIN_BONGO_DELAY: float = 1.0
const MAX_BONGO_DELAY: float = 7.0

var bongo_delay: float = randf_range(MIN_BONGO_DELAY, MAX_BONGO_DELAY)
var last_pitter_patter: int = -1


func _physics_process(delta: float) -> void :
 if Engine.is_editor_hint():
  return

 if anim_player.assigned_animation != "idle":
  return
 else:
  bongo_delay = maxf(bongo_delay - delta, 0.0)
  if bongo_delay > 0.0:
   return

 bongo_delay = randf_range(MIN_BONGO_DELAY, MAX_BONGO_DELAY)

 var pitter_patter: int = randi_range(1, 3)
 while pitter_patter == last_pitter_patter:
  pitter_patter = randi_range(1, 3)

 last_pitter_patter = pitter_patter
 anim_player.play("pitter_patter_%d" % pitter_patter)
 anim_player.queue("idle")
