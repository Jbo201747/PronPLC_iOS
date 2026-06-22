class_name SpellChargeDecay extends RefCounted


var interval_sec: = 10
var timer: GameTimer = GameTimer.new()
var spell_ref: WeakRef
var spell: Spell:
 get():
  return spell_ref.get_ref()
 set(value):
  spell_ref = weakref(value)


func _init(_spell: Spell, _interval_sec: = 10):
 spell = _spell
 interval_sec = _interval_sec
 timer.stopped.connect(_on_timer_stopped)


func _process(_delta: float):
 if not timer.is_running() or spell == null or spell.charge_container == null:
  return

 if spell.has_usable_charge():
  var remaining_ms: = timer.get_remaining_time(interval_sec * 1000)
  if remaining_ms <= 0:
   spell.remove_charge(1)
   timer.start()
  elif remaining_ms <= 3000:
   spell.charge_container.flash_last_charge("flash_fast")
  else:
   spell.charge_container.flash_last_charge("flash_slow")


func _on_timer_stopped(_elapsed_time: int) -> void :
 spell.charge_container.stop_flashing()
