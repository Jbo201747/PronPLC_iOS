@tool
class_name AnimPlayer extends AnimationPlayer

signal event_emitted(event_name: String)
signal flag_changed(flag_name: String)

signal animation_stopped(anim_name: StringName)

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var event: String = "":
 set(value):
  if Engine.is_editor_hint():
   event = value

  handle_event(value)
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var set_flag: String = "":
 set(value):
  if Engine.is_editor_hint():
   set_flag = value

  set_animation_flag(value, true)
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var unset_flag: String = "":
 set(value):
  if Engine.is_editor_hint():
   unset_flag = value

  set_animation_flag(value, false)
@export_custom(PROPERTY_HINT_ENUM, "None", PROPERTY_USAGE_EDITOR) var sound: String = "None":
 set(value):
  if Engine.is_editor_hint():
   sound = value

  handle_sound(value)
@export_custom(PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, "None"], PROPERTY_USAGE_EDITOR) var sounds: PackedStringArray:
 set(value):
  if Engine.is_editor_hint():
   sounds = value

  handle_sounds(value)
@export_enum("None") var sound_groups: PackedStringArray
@export_custom(PROPERTY_HINT_TYPE_STRING, "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, "None"], PROPERTY_USAGE_EDITOR) var reset_sounds: PackedStringArray:
 set(value):
  if Engine.is_editor_hint():
   reset_sounds = value

  for sound_name in value:
   reset_sound(sound_name)
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "AnimRef", PROPERTY_USAGE_EDITOR) var play_anim: AnimRef:
 set(value):
  if value == null or (Engine.is_editor_hint() and not is_playing()):
   return

  value.play(self)
@export var global_pitch_scale: float = 1.0
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var disable_sound: bool = false

var animation_flags: Dictionary[String, bool] = {}


func _ready() -> void :
 animation_finished.connect(_on_animation_finished)
 animation_changed.connect(_on_animation_changed)


func _on_animation_finished(anim_name: StringName) -> void :
 animation_stopped.emit(anim_name)


func _on_animation_changed(old_name: StringName, _new_name: StringName) -> void :
 animation_stopped.emit(old_name)


func _validate_property(property: Dictionary) -> void :
 if not Engine.is_editor_hint():
  return

 if property.name in ["sound", "sounds", "reset_sounds"]:
  Sounds.validate_sound_property(property, false, sound_groups)
 elif property.name == "sound_groups":
  Sounds.validate_sound_property(property, true)


func _notification(what: int) -> void :
 if what == NOTIFICATION_EDITOR_PRE_SAVE:
  if has_animation("RESET"):
   var reset_anim: = get_animation("RESET")
   var num_tracks: = reset_anim.get_track_count()
   for i in range(num_tracks - 1, -1, -1):
    var path: = reset_anim.track_get_path(i)
    var subname_count: = path.get_subname_count()
    if subname_count > 0:
     var property: = path.get_subname(path.get_subname_count() - 1)
     if property in ["sound", "sounds", "event", "reset_sounds", "play_anim", "set_flag", "unset_flag"]:
      reset_anim.remove_track(i)


func play_advance(anim_name: StringName = &"", instant: bool = false, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void :
 var disabled_sound: = false
 if instant and not disable_sound:
  disabled_sound = true
  disable_sound = true

 play(anim_name, custom_blend, custom_speed, from_end)

 if instant:
  advance(current_animation_length)
  if disabled_sound:
   disable_sound = false
 else:
  advance(0.0)


func play_until_finished(anim_name: StringName = &"", instant: bool = false, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void :
 play_advance(anim_name, instant, custom_blend, custom_speed, from_end)
 if not instant:
  await animation_stopped


func play_reversible_appear_disappear(appearing: = true, instant: = false, appear: = &"appear", disappear: = &"disappear") -> void :
 var playing: = is_playing()

 if instant:
  if appearing:
   play_advance(appear, instant)
  else:
   play_advance(disappear, instant)

  return

 if assigned_animation == appear:
  if appearing:
   if speed_scale < 0:
    speed_scale = 1.0

   if not playing and current_animation_position < current_animation_length:
    play_advance(appear)
  else:
   if playing:
    speed_scale = -1.0
   elif current_animation_position > 0.0:
    play_advance(disappear)
 else:
  if appearing:
   if playing:
    speed_scale = -1.0
   elif current_animation_position > 0.0:
    play_advance(appear)
  else:
   if speed_scale < 0:
    speed_scale = 1.0

   if not playing and current_animation_position < current_animation_length:
    play_advance(disappear)




func pend_animation_stopped(anim_name: StringName = &"") -> void :
 while current_animation == anim_name or anim_name in get_queue():
  await animation_stopped




func pend_animation_played(anim_name: StringName = &"") -> void :
 while current_animation != anim_name:
  await animation_changed


func pend_any_animation_played(anim_names: Array[StringName] = []):
 while current_animation not in anim_names:
  await animation_changed


func reset_sound(sound_name: String) -> void :
 if sound_name in Sounds.SOUND_CONSTANTS:
  if Engine.is_editor_hint():
   if is_playing():
    return

   var manager: = AudioManagerSingleton.get_temporary_audio_manager(get_tree())
   manager.reset_sound(Sounds.SOUND_CONSTANTS[sound_name])
  else:
   AudioManager.reset_sound(Sounds.SOUND_CONSTANTS[sound_name])


func play_sound(sound_data: Variant, pitch_scale: float = -1.0, volume: = 1.0, bus: = "Sound") -> AudioManagerSingleton.SoundPlayback:
 var manager: AudioManagerSingleton
 if Engine.is_editor_hint():
  if not is_playing():
   return

  manager = AudioManagerSingleton.get_temporary_audio_manager(get_tree())
 else:
  manager = AudioManager

 if pitch_scale == -1.0:
  pitch_scale = global_pitch_scale

 return manager.play_sound(sound_data, pitch_scale, volume, bus, self)


func handle_sound(sound_name: String) -> void :
 if disable_sound:
  return

 if Engine.is_editor_hint():
  Sounds.refresh_sounds()

 if sound_name in Sounds.SOUND_CONSTANTS:
  play_sound(Sounds.SOUND_CONSTANTS[sound_name])


func handle_sounds(sounds_list: PackedStringArray) -> void :
 for sound_name in sounds_list:
  handle_sound(sound_name)


func handle_event(event_name: String) -> void :
 event_emitted.emit(event_name)


func set_animation_flag(flag_name: String, value: bool) -> void :
 animation_flags[flag_name] = value
 flag_changed.emit(flag_name)


func get_animation_flag(flag_name: String) -> bool:
 return animation_flags.get(flag_name, false)


func pend_flag(flag_name: String, value: bool) -> void :
 if get_animation_flag(flag_name) == value:
  return

 while true:
  var changed_flag: String = await flag_changed
  if changed_flag == flag_name and get_animation_flag(flag_name) == value:
   return


func pend_event(event_name: String):
 while true:
  var emitted_name: String = await event_emitted

  if event_name == emitted_name:
   return
