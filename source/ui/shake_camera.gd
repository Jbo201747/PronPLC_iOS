class_name ShakeCamera extends Camera2D


var shake_noise: FastNoiseLite = FastNoiseLite.new()
var shake_seed: Vector2 = Vector2.ZERO
var active_shake_direction: Vector2 = Vector2.RIGHT

var quakes: Array[Quake] = []
var total_quake_duration: float = 0.0


func _ready():
 anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
 randomize_shake()
 shake_noise.fractal_type = FastNoiseLite.FRACTAL_NONE


func randomize_shake() -> void :
 active_shake_direction = Vector2.RIGHT
 shake_noise.seed = randi()
 shake_seed = Vector2(randf() * 1000000, randf() * 1000000)


func _process(delta: float) -> void :
 var total_intensity = 0

 if not quakes.is_empty():
  total_quake_duration += delta
 else:
  total_quake_duration = 0.0

 for i in range(quakes.size() - 1, -1, -1):
  var quake: Quake = quakes[i]

  total_intensity += quake.get_intensity()
  quake._process(delta)

  if quake.is_finished():
   quakes.remove_at(i)
   if quakes.is_empty():
    randomize_shake()
    total_intensity = 0.0

 total_intensity = min(total_intensity, 16.0)
 total_intensity *= SaveManager.get_screenshake_setting()

 var shake_direction: = active_shake_direction

 var new_offset: = Vector2.ZERO
 if total_intensity > 0:
  var time: = float(Time.get_ticks_msec()) / 1000.0

  var shake_wave: = sin(20.0 * (time + shake_seed.x + shake_seed.y))
  var direction_noise: = Vector2(
   shake_noise.get_noise_2d(shake_seed.x, time * 100.0), 
   shake_noise.get_noise_2d(shake_seed.y, time * 100.0)
  )
  shake_direction = (shake_direction + direction_noise * 1.0).normalized()
  new_offset = shake_direction * shake_wave * total_intensity

 offset = new_offset


func shake(intensity: float, falloff_duration: float, sustain_duration: float = 0.0, no_randomize: = false):
 if SaveManager.get_screenshake_setting() != 0:
  if not no_randomize:
   randomize_shake()

  var quake = Quake.new(intensity, sustain_duration, falloff_duration)
  quakes.append(quake)


class Quake:
 var intensity: float
 var duration: float
 var falloff_duration: float

 var lifetime: float = 0.0

 func _init(_intensity: float, _duration: float, _falloff_duration: float = 0.18) -> void :
  intensity = _intensity
  duration = _duration
  falloff_duration = _falloff_duration


 func _process(delta: float) -> void :
  lifetime += delta


 func is_finished() -> bool:
  return lifetime > duration + falloff_duration


 func get_intensity() -> float:
  if lifetime < duration:
   return intensity

  var falloff_time = lifetime - duration
  if falloff_time > falloff_duration:
   return 0.0

  return lerpf(intensity, 0.0, falloff_time / falloff_duration)
