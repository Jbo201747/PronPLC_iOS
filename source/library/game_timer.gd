class_name GameTimer extends RefCounted

signal started
signal stopped(time_elapsed: int)
signal active_changed

var start_time: int = 0
var elapsed_time: int = 0
var is_paused: = false
var is_active: = false:
 set(value):
  if is_active != value:
   is_active = value
   active_changed.emit()


func _init(turn_timer: bool = true) -> void :
 if turn_timer:
  Game.start_turn_timers.connect(start)
  Game.stop_turn_timers.connect(stop)
  Game.pause_turn_timers.connect(pause)
  Game.resume_turn_timers.connect(resume)


func start() -> void :
 if is_active:
  stop()

 elapsed_time = 0
 start_time = Time.get_ticks_msec()
 is_active = true
 is_paused = false
 started.emit()


func stop() -> void :
 if not is_active:
  return

 stopped.emit(get_elapsed_time())
 is_active = false


func pause() -> void :
 if not is_active or is_paused:
  return

 elapsed_time += _get_elapsed_ticks()
 is_paused = true


func resume() -> void :
 if not is_active or not is_paused:
  return

 start_time = Time.get_ticks_msec()
 is_paused = false


func get_elapsed_time() -> int:
 return (_get_elapsed_ticks() + elapsed_time)


func get_remaining_time(total_time: int, time_scale: int = 1) -> int:
 return maxi(0, total_time - get_elapsed_time() * time_scale)


func is_running() -> bool:
 return is_active and not is_paused


func _get_elapsed_ticks() -> int:
 return Time.get_ticks_msec() - start_time
