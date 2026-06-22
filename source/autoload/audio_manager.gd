@tool
class_name AudioManagerSingleton extends Node

const MUSIC_FADE_TIME = 0.2

var active_music: Variant

var music_fade_tween: Tween

var music_bus = AudioServer.get_bus_index("Music")
var lpf_bus = AudioServer.get_bus_index("LowPass")

var effects: Dictionary[String, GameAudioEffect] = {
 pause = GameAudioEffect.new(0.5, 1.0, 1000.0, false, 1), 
 fishing = GameAudioEffect.new(1.0, 1.0, 1000.0, true, 1, 500.0), 
 brutalist = GameAudioEffect.new(1.0, 1.0, 2000.0, true), 
 phonebook = GameAudioEffect.new(1.0, 1.0, 1000.0, true), 
 salt = GameAudioEffect.new(1.0, 1.11), 
 salt_evil_a = GameAudioEffect.new(1.0, 1.3), 
 salt_evil_b = GameAudioEffect.new(1.0, 0.6), 
 cutscene_mute = GameAudioEffect.new(0.0, 1.0), 
 duck_music = GameAudioEffect.new(0.2, 1.0), 
}

var playing_sounds: Dictionary[Variant, Array] = {}
var sound_repeat: Dictionary[Dictionary, Dictionary] = {}

var temporary_instance: = false
var time_without_sound: = 0.0

var rng: = RNG.new()

@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var sound_player: AudioStreamPlayer = %SoundPlayer
@onready var music_filter_sound_player: AudioStreamPlayer = %SoundPlayerMusicFilter
@onready var lowpass_sound_player: AudioStreamPlayer = %SoundPlayerLowpass


func _ready() -> void :
 rng.reseed()

 for key in effects:
  effects[key].effect_process_changed.connect(_on_effect_process_changed)

 if not temporary_instance:
  set_process(false)


func _process(delta: float) -> void :
 if temporary_instance:
  if sound_player.has_stream_playback():
   time_without_sound = 0.0
  else:
   time_without_sound += delta

  if time_without_sound > 10.0:
   queue_free()

  return

 var min_volume: float = 1.0
 var min_lpf_cutoff: float = 20500.0
 var pitch_scale: float = 1.0

 var max_effect_layer: int = 0
 var effect_layers: Dictionary[int, Array] = {}
 for key in effects:
  var effect: = effects[key]
  effect._process(delta)
  if effect.layer not in effect_layers:
   effect_layers[effect.layer] = []

  effect_layers[effect.layer].append(effect)
  max_effect_layer = maxi(max_effect_layer, effect.layer)

 for i in max_effect_layer + 1:
  if i not in effect_layers:
   continue

  var volume_before_layer: = min_volume
  var lpf_before_layer: = min_lpf_cutoff

  for effect: GameAudioEffect in effect_layers[i]:
   min_volume = minf(min_volume, effect.get_volume(volume_before_layer))
   min_lpf_cutoff = minf(min_lpf_cutoff, effect.get_lpf_cutoff(lpf_before_layer))
   pitch_scale *= effect.get_pitch_scale()

 var is_lpf: = min_lpf_cutoff < 20500.0
 AudioServer.set_bus_effect_enabled(lpf_bus, 0, is_lpf)
 var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(lpf_bus, 0)
 filter.cutoff_hz = min_lpf_cutoff
 AudioServer.set_bus_volume_db(lpf_bus, linear_to_db(min_volume))

 music_player.pitch_scale = pitch_scale


func _on_effect_process_changed() -> void :
 var any_effect_active: = false
 for key in effects:
  if effects[key].fade_active:
   any_effect_active = true
   break

 if not temporary_instance:
  set_process(any_effect_active)


func kill_effects(weak_only: = false) -> void :
 for key in effects:
  if effects[key].is_active() and ( not weak_only or effects[key].is_weak):
   effects[key].set_enabled(false, 0.0)


func _on_sound_playback_finished(sound: Variant, playback: SoundPlayback) -> void :
 if sound in playing_sounds:
  playing_sounds[sound].erase(playback)
  if playing_sounds[sound].is_empty():
   playing_sounds.erase(sound)


func stop_sound(sound: Variant) -> void :
 if sound in playing_sounds:
  for playback: SoundPlayback in playing_sounds[sound]:
   playback.stop()


func reset_sound(sound: Variant) -> void :
 stop_sound(sound)
 if sound in sound_repeat:
  sound_repeat.erase(sound)


func get_node_sounds(node: Node) -> Array[SoundPlayback]:
 if node == null:
  return []

 var node_playbacks: Array[SoundPlayback] = []
 for sound in playing_sounds:
  for playback: SoundPlayback in playing_sounds[sound]:
   if playback.node == node:
    node_playbacks.append(playback)

 return node_playbacks


func stop_node_sounds(node: Node) -> void :
 for playback in get_node_sounds(node):
  playback.stop()


func fade_sounds(duration: float = 0.1) -> void :
 for sound in playing_sounds:
  for playback: SoundPlayback in playing_sounds[sound]:
   playback.fade_out(duration)


func play_sound(sound: Variant, pitch_scale: float = 1.0, volume: float = 1.0, bus = "Sound", node: Node = null) -> SoundPlayback:
 if sound is SoundRef:
  play_sound(sound.sound, pitch_scale, volume, bus, node)
  return
 elif sound is String:
  if sound not in Sounds.SOUND_CONSTANTS:
   return
  else:
   play_sound(Sounds.SOUND_CONSTANTS[sound], pitch_scale, volume, bus, node)
   return

 var audio_stream: AudioStream = null
 var play_from: float = 0.0
 var stop_on_tree_exit: bool = false
 if sound is AudioStream:
  audio_stream = sound
 elif sound is Dictionary:
  if "IN_GAME_ONLY" in sound and not Game.is_in_run():
   return null

  if "SOUND" in sound:
   audio_stream = sound.SOUND
  elif "SOUNDS" in sound:
   var repeat: bool = sound.get("REPEAT", false)
   var cycle: bool = sound.get("CYCLE", false)

   var pool: Variant = sound.SOUNDS.duplicate()
   if pool is Array and (cycle or not repeat):
    if sound not in sound_repeat:
     sound_repeat[sound] = {}

    if "last_played" in sound_repeat[sound]:
     if cycle:
      var pool_array: = pool as Array
      var index: int = pool_array.find(sound_repeat[sound].last_played)
      var next_index: int = posmod(index + 1, pool_array.size())
      audio_stream = pool_array[next_index]
     elif not repeat:
      pool.erase(sound_repeat[sound].last_played)
    elif cycle:
     audio_stream = pool[0]

   if audio_stream == null:
    if pool is Dictionary:
     audio_stream = rng.weighted_random(pool)
    else:
     audio_stream = rng.pick_random(pool)

   if sound in sound_repeat:
    sound_repeat[sound].last_played = audio_stream

  if "PITCH_VARIANCE" in sound:
   if sound.PITCH_VARIANCE is Vector2:
    pitch_scale += rng.randf_range(sound.PITCH_VARIANCE.x, sound.PITCH_VARIANCE.y)
   else:
    pitch_scale += rng.randf_range( - sound.PITCH_VARIANCE, sound.PITCH_VARIANCE)

  if "PITCH_SCALE" in sound:
   pitch_scale *= sound.PITCH_SCALE

  if "VOLUME" in sound:
   volume *= sound.VOLUME

  if "PLAY_FROM" in sound:
   play_from = sound.PLAY_FROM

  if "RESET_ON_PLAY" in sound:
   reset_sound(sound)
  elif "STOP_ON_PLAY" in sound:
   stop_sound(sound)

  if "STOP_ON_TREE_EXIT" in sound:
   stop_on_tree_exit = true

 var player: AudioStreamPlayer = sound_player
 if bus == "SoundLowpass":
  player = music_filter_sound_player
 elif bus == "SoundLowpassConst":
  player = lowpass_sound_player

 if not player.has_stream_playback():
  player.play()

 var playback: AudioStreamPlaybackPolyphonic = player.get_stream_playback()
 var sound_id: = playback.play_stream(audio_stream, play_from, linear_to_db(volume), pitch_scale, player.playback_type, bus)

 var stream_playback: = SoundPlayback.new(sound_id, audio_stream, volume, pitch_scale, node, stop_on_tree_exit, player)

 if sound not in playing_sounds:
  playing_sounds[sound] = []

 playing_sounds[sound].append(stream_playback)

 stream_playback.finished.connect(_on_sound_playback_finished.bind(sound, stream_playback))

 return stream_playback


func get_sound_playback() -> AudioStreamPlaybackPolyphonic:
 return sound_player.get_stream_playback()


func stop_music(stop_effects: = true) -> void :
 if music_player.finished.is_connected(_on_music_intro_finished):
  music_player.finished.disconnect(_on_music_intro_finished)

 if music_fade_tween and music_fade_tween.is_running():
  music_fade_tween.kill()

 if stop_effects:
  kill_effects(true)

 music_player.stop()


func play_music(song: Variant, do_intro: = false, override_volume: float = -1.0):
 stop_music(do_intro)

 active_music = song
 music_player.volume_db = 0
 if song is Dictionary:
  if "LOOP_INTRO" in song:
   song.INTRO.loop = song.LOOP_INTRO

  if "VOLUME" in song:
   music_player.volume_db = linear_to_db(song.VOLUME)

  if "INTRO" in song and do_intro:
   music_player.finished.connect(_on_music_intro_finished, ConnectFlags.CONNECT_ONE_SHOT)
   music_player.set_stream(song.INTRO)
  else:
   if "LOOP_VOLUME" in song:
    music_player.volume_db = linear_to_db(song.LOOP_VOLUME)

   music_player.set_stream(song.LOOP)
 else:
  music_player.set_stream(song)

 if override_volume != -1.0:
  music_player.volume_db = linear_to_db(override_volume)

 music_player.play()


func fade_music(fade_time: float = MUSIC_FADE_TIME) -> void :
 if music_fade_tween and music_fade_tween.is_running():
  return

 if music_player.finished.is_connected(_on_music_intro_finished):
  music_player.finished.disconnect(_on_music_intro_finished)

 music_fade_tween = create_tween()
 music_fade_tween.tween_property(music_player, "volume_linear", 0.0, fade_time)


func _on_music_intro_finished():
 play_music(active_music)


static func get_temporary_audio_manager(tree: SceneTree) -> AudioManagerSingleton:
 var existing_manager: = tree.get_first_node_in_group("temporary_audio_manager")
 if existing_manager != null:
  return existing_manager
 else:
  var scene: = load("res://source/autoload/audio_manager.tscn")
  var manager: AudioManagerSingleton = scene.instantiate()
  manager.temporary_instance = true
  manager.add_to_group("temporary_audio_manager")
  tree.root.add_child(manager)
  return manager


class GameAudioEffect:
 signal effect_process_changed

 var lpf_cutoff: float = 20500.0
 var volume: float = 1.0
 var pitch_scale: float = 1.0

 var layer: int = 0
 var stacked_lpf: float = 20500.0

 var fade_timer: float = 0.0
 var fade_finish: float = 0.0

 var sustain_timer: float = -1.0
 var auto_fade_out: float = -1.0

 var is_weak: = false

 var enabling: = false
 var fade_active: = false:
  set(value):
   if fade_active != value:
    fade_active = value
    effect_process_changed.emit()


 func _init(_volume: float, _pitch_scale: float, _lpf_cutoff: float = 20500.0, _is_weak: bool = false, _layer: int = 0, _stacked_lpf: float = 20500.0) -> void :
  volume = _volume
  pitch_scale = _pitch_scale
  lpf_cutoff = _lpf_cutoff
  is_weak = _is_weak
  stacked_lpf = _stacked_lpf
  layer = _layer


 func _process(delta: float) -> void :
  fade_timer = clampf(fade_timer + delta, 0.0, fade_finish)
  if fade_timer >= fade_finish:
   if sustain_timer > 0.0:
    sustain_timer = maxf(sustain_timer - delta, 0.0)
    if sustain_timer <= 0.0:
     set_enabled(false, auto_fade_out)
   else:
    fade_active = false


 func is_active() -> bool:
  return fade_active or enabling


 func safe_fade(base: float, target: float) -> float:
  if fade_finish <= 0.0:
   return target
  else:
   return lerpf(base, target, fade_timer / fade_finish)


 func get_volume(volume_before_layer: float = 1.0) -> float:
  var base: float = volume_before_layer if enabling else volume
  var target: float = volume if enabling else volume_before_layer
  return safe_fade(base, target)


 func get_lpf_cutoff(lpf_before_layer: float = 20500.0) -> float:
  var target_cutoff: = lpf_cutoff
  if stacked_lpf != 20500.0 and lpf_before_layer != 20500.0:
   target_cutoff = stacked_lpf

  var base: float = lpf_before_layer if enabling else target_cutoff
  var target: float = target_cutoff if enabling else lpf_before_layer
  return safe_fade(base, target)


 func get_pitch_scale() -> float:
  var base: float = 1.0 if enabling else pitch_scale
  var target: float = pitch_scale if enabling else 1.0
  return safe_fade(base, target)


 func can_stack_lpf() -> bool:
  return stacked_lpf != 20500.0


 func set_enabled(enabled: bool, fade_in: float = 0.2, sustain: float = -1.0, fade_out: float = -1.0) -> void :
  if fade_active and fade_finish > 0.0:
   var current_fade_progress: = fade_timer / fade_finish
   if enabling == enabled:
    fade_timer = lerpf(0.0, fade_in, current_fade_progress)
   else:
    fade_timer = lerpf(0.0, fade_in, 1.0 - current_fade_progress)
  else:
   fade_timer = 0.0

  if enabled:
   sustain_timer = sustain
   auto_fade_out = fade_out

  fade_finish = fade_in
  enabling = enabled
  fade_active = true


class SoundPlayback extends RefCounted:
 signal finished

 var audio_player: AudioStreamPlayer

 var is_valid: bool = true
 var playback_id: int
 var length: float = 0.0
 var base_volume: float = 0.0
 var stop_on_tree_exit: bool = false
 var timer: CancelableTimeout
 var node: Node:
  set(value):
   if node != null:
    if node.tree_exiting.is_connected(_node_exited):
     node.tree_exiting.disconnect(_node_exited)

   node = value

   if node != null:
    node.tree_exiting.connect(_node_exited)
 var fade_tween: Tween = null


 func _init(_playback_id: int, stream: AudioStream, volume: float, pitch_scale: float, _node: Node, _stop_on_tree_exit: bool, _audio_player: AudioStreamPlayer) -> void :
  stop_on_tree_exit = _stop_on_tree_exit
  node = _node
  audio_player = _audio_player
  playback_id = _playback_id
  base_volume = volume
  length = stream.get_length()

  if stream is AudioStreamOggVorbis:
   if stream.loop:
    if Engine.is_editor_hint():
     stream.loop = false
    else:
     return
  elif stream is AudioStreamWAV:
   if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
    if Engine.is_editor_hint():
     stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    else:
     return

  timer = CancelableTimeout.new(audio_player.get_tree(), length * (1.0 / pitch_scale))
  timer.cancel_or_timeout.connect(_finish)


 func set_volume(volume: float) -> void :
  base_volume = volume
  if audio_player.has_stream_playback():
   var playback: AudioStreamPlaybackPolyphonic = audio_player.get_stream_playback()
   if playback.is_stream_playing(playback_id):
    playback.set_stream_volume(playback_id, linear_to_db(volume))


 func fade_out(duration: float = 0.1) -> void :
  if audio_player.has_stream_playback():
   var playback: AudioStreamPlaybackPolyphonic = audio_player.get_stream_playback()
   if playback.is_stream_playing(playback_id):
    fade_tween = audio_player.create_tween()
    fade_tween.tween_method(_fade_tween_callback.bind(playback), base_volume, 0.0, duration)
    await fade_tween.finished

  stop()


 func _fade_tween_callback(volume: float, playback: AudioStreamPlaybackPolyphonic) -> void :
  if is_instance_valid(playback) and playback.is_stream_playing(playback_id):
   playback.set_stream_volume(playback_id, linear_to_db(volume))


 func kill_fade() -> void :
  if fade_tween != null:
   fade_tween.kill()


 func stop() -> void :
  kill_fade()
  if audio_player.has_stream_playback():
   var playback: AudioStreamPlaybackPolyphonic = audio_player.get_stream_playback()
   if playback.is_stream_playing(playback_id):
    playback.stop_stream(playback_id)

  if timer != null:
   timer.cancel()
  elif is_valid:
   _finish()


 func _node_exited() -> void :
  if is_valid and stop_on_tree_exit:
   stop()
  node = null


 func _finish() -> void :
  kill_fade()
  is_valid = false
  finished.emit()
