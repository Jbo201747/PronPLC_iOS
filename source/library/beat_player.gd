class_name BeatPlayer extends Node

signal beat
signal interval_beat
signal beat_animated

@export var beat_interval: int = 2
@export var high_bpm_interval: int = 3
@export var bpm_threshold: float = 120.0

@export var beat_anims: Array[AnimRef] = []

@export var disabled: bool = false

var previous_beats: = -1
var loop_count: = -1
var loop_beats: = -1

var beat_anim_names: Array[StringName] = []


func _ready() -> void :
 for anim in beat_anims:
  beat_anim_names.append(anim.anim_name)


func _process(_delta):
 if not AudioManager.music_player.is_playing():
  return

 var prev_total_beats: int = previous_beats + loop_beats

 var playback: = AudioManager.music_player.get_stream_playback()
 if playback.get_loop_count() != loop_count:
  loop_count = playback.get_loop_count()
  previous_beats += maxi(loop_beats, 0) + 1

 var time = AudioManager.music_player.get_playback_position() + AudioServer.get_time_since_last_mix()
 time -= AudioServer.get_output_latency()

 var bpm: float = 120.0
 if AudioManager.music_player.stream is AudioStreamOggVorbis:
  bpm = AudioManager.music_player.stream.bpm

 var current_interval: int = beat_interval
 if bpm > bpm_threshold and high_bpm_interval != -1:
  current_interval = high_bpm_interval

 var beat_duration: float = 60.0 / bpm

 loop_beats = int(time / beat_duration)

 var total_beats: = previous_beats + loop_beats
 if prev_total_beats != total_beats:
  beat.emit()
  if total_beats % current_interval == 0:
   interval_beat.emit()

   if not disabled and not beat_anims.is_empty():
    var beat_anim_index: int = -1
    for anim_ref in beat_anims:
     var player: AnimationPlayer = get_node_or_null(anim_ref.anim_player)
     if player == null:
      return

     if player.is_playing() and player.current_animation not in beat_anim_names:
      return

     if player.assigned_animation in beat_anim_names:
      beat_anim_index = beat_anim_names.find(player.assigned_animation)

    var next_anim_index: int = 0
    if beat_anim_index != -1:
     next_anim_index = (beat_anim_index + 1) % beat_anims.size()

    beat_anims[next_anim_index].play(self)
    beat_animated.emit()
