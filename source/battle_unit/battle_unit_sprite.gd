@tool
class_name BattleUnitSprite extends Node2D

signal active_sprite_changed

signal hit
signal appeared
signal animation_looped

signal event_emitted(event)
signal flag_changed(flag: String)

signal hovered_on
signal hovered_off
signal hover_area_input(viewport: Viewport, input_event: InputEvent, shape_idx: int)

var Poofcloud = preload("res://source/effects/poofcloud_small.tscn")
var BigPoofcloud = preload("res://source/effects/poofcloud.tscn")
var BloodExplosion = preload("res://source/effects/blood_explosion.tscn")

@export var phonebook_hidden_when_locked: Array[Node] = []
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
  if value == null or (Engine.is_editor_hint() and not anim_player.is_playing()):
   return

  value.play(self)
@export var global_pitch_scale: float = 1.0
@export var big_explosion_count: int = 1
@export var small_explosion_count: int = 3
@export var show_editor_background: bool = false:
 set(value):
  show_editor_background = value
  update_editor_background()
@export var show_screen_border: bool = false:
 set(value):
  show_screen_border = value
  update_editor_background()
@export var intents_realign_above_word: bool = false:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.intents_realign_above_word
  else:
   return intents_realign_above_word

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var sound_disabled: = false

var animation_flags: Dictionary[String, bool] = {}

var bleed_override = null
var bleed_blend = null
var bleed_blend_duration: float = 1.0

var unit_is_enemy: bool = false
var unit_id: String = ""
var initial_phonebook_animation: String = ""
var playing_phonebook_animation: Variant = null

var sub_sprites: Array[BattleUnitSprite] = []
var active_sub_sprite: BattleUnitSprite = null

var is_hovered: = false

@onready var anim_player: AnimPlayer = $AnimPlayer:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.anim_player
  else:
   return anim_player
@onready var bleed_area: Area2D = %BleedArea:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.bleed_area
  else:
   return bleed_area
@onready var hover_area: Area2D = %HoverArea:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.hover_area
  else:
   return hover_area
@onready var hit_marker: Marker2D = $HitMarker:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.hit_marker
  else:
   return hit_marker
@onready var intent_marker: TransformMarker = %IntentMarker:
 get():
  if active_sub_sprite != null:
   return active_sub_sprite.intent_marker
  else:
   return intent_marker


func _ready() -> void :
 update_editor_background()


func _validate_property(property: Dictionary) -> void :
 if not Engine.is_editor_hint():
  return

 if property.name in ["sound", "sounds", "reset_sounds"]:
  Sounds.validate_sound_property(property, false, sound_groups)
 elif property.name == "sound_groups":
  Sounds.validate_sound_property(property, true)


func update_editor_background() -> void :
 if not Engine.is_editor_hint():
  return

 var editor_interface = Engine.get_singleton("EditorInterface")
 if self != editor_interface.get_edited_scene_root():
  return

 if show_screen_border:
  if not has_node("ScreenBorder"):
   var sprite: = Sprite2D.new()
   sprite.texture = load("res://arte/screen_border.png")
   sprite.modulate = Color(1448514815)
   sprite.centered = false
   sprite.name = "ScreenBorder"
   add_child(sprite)
   sprite.position -= Vector2(394, 189)
 elif has_node("ScreenBorder"):
  get_node("ScreenBorder").queue_free()

 if show_editor_background:
  if not has_node("GameBG"):
   var act_and_floor: Variant = null
   for enemy in Enemies.list():
    if enemy in scene_file_path:
     act_and_floor = Enemies.get_act_and_floor(enemy)
     break

   if act_and_floor == null:
    act_and_floor = {act = 0}

   if act_and_floor != null:
    var background: = GameBG.new()
    background.layers = load("res://data/backgrounds/act_%d/background.tres" % (act_and_floor.act + 1))
    background.name = "GameBG"
    add_child(background)
    background.initialize_layers()
    background.offset -= Vector2(240, 187)
    background.layer = -100
 elif has_node("GameBG"):
  get_node("GameBG").queue_free()


func set_unit_id(id: String) -> void :
 unit_id = id
 for sprite in sub_sprites:
  sprite.set_unit_id(id)


func bleed() -> void :
 AudioManager.reset_sound(Sounds.GENERIC.BLOOD_EXPLODE)
 AudioManager.play_sound(Sounds.GENERIC.BLOOD_EXPLODE)

 if bleed_override != null:
  bleed_poof(bleed_override)
 else:
  bleed_poof(get_blood_color())


func bleed_poof(color: Color) -> void :
 var poofcloud

 if randi_range(0, 1) == 0:
  poofcloud = Poofcloud.instantiate()
 else:
  poofcloud = BigPoofcloud.instantiate()

 Game.main.add_child(poofcloud)

 poofcloud.global_position = Util.random_point_in_collision_object(bleed_area, Game.random)
 poofcloud.modulate = color

 if bleed_blend != null:
  poofcloud.color_fade(bleed_blend, bleed_blend_duration)

 Game.screenshake(4, 0.32)


func blood_explode():
 if bleed_override != null:
  blood_explode_poof(bleed_override)
 else:
  blood_explode_poof(get_blood_color())


func blood_explode_poof(color: Color) -> void :
 AudioManager.reset_sound(Sounds.GENERIC.BLOOD_EXPLODE)
 AudioManager.play_sound(Sounds.GENERIC.BLOOD_EXPLODE, 1.1)

 Game.screenshake(12, 0.32)

 var center: = Util.get_collision_object_rect(bleed_area).get_center()
 if big_explosion_count > 1:
  for offset in get_circle_offsets(big_explosion_count, 40.0, 2.5):
   spawn_big_blood_explosion(color, center + offset, offset.angle(), 0.0, TAU / (big_explosion_count + 1))
 else:
  spawn_big_blood_explosion(color, center)


func get_circle_offsets(count: int, distance: float, angle_variance: float, base_angle: float = 0.0, base_angle_variance: float = TAU, circle_angle_total: float = TAU) -> PackedVector2Array:
 var array: = PackedVector2Array()
 base_angle += randf_range( - base_angle_variance / 2.0, base_angle_variance / 2.0) - circle_angle_total / 2.0
 var base_offset: Vector2 = Vector2(distance, 0.0).rotated(base_angle)
 var angle_per: float
 if circle_angle_total == TAU:
  angle_per = circle_angle_total / count
 else:
  angle_per = circle_angle_total / (count - 1)

 for i in count:
  var circle_angle: float = angle_per * i
  var random_angle: float = deg_to_rad(randf_range( - angle_variance, angle_variance))
  var offset: Vector2 = base_offset.rotated(circle_angle + random_angle)
  array.append(offset)

 return array


func spawn_big_blood_explosion(color: Color, explosion_position: Vector2, base_angle: = 0.0, base_angle_variance: = TAU, circle_angle_total: = TAU) -> void :
 var blood_explosion = BloodExplosion.instantiate()
 Game.main.add_child(blood_explosion)
 blood_explosion.global_position = explosion_position

 blood_explosion.modulate = color
 if bleed_blend != null:
  blood_explosion.color_fade(bleed_blend, bleed_blend_duration)

 for offset in get_circle_offsets(small_explosion_count, 40.0, 5.0, base_angle, base_angle_variance, circle_angle_total):
  var offset_position = blood_explosion.global_position + offset
  var sub_poofcloud = Poofcloud.instantiate()

  Game.main.add_child(sub_poofcloud)

  sub_poofcloud.z_index = blood_explosion.z_index + 1
  sub_poofcloud.global_position = offset_position
  sub_poofcloud.modulate = color

  if bleed_blend != null:
   sub_poofcloud.color_fade(bleed_blend, bleed_blend_duration)

  await Game.timeout(0.08)


func screenshake(intensity: float, falloff_duration: float, sustain_duration: float = 0.0) -> void :
 Game.screenshake(intensity, falloff_duration, sustain_duration)


func reset_sound(sound_name: String) -> void :
 if sound_name in Sounds.SOUND_CONSTANTS:
  if Engine.is_editor_hint():
   if not anim_player.is_playing():
    return

   var manager: = AudioManagerSingleton.get_temporary_audio_manager(get_tree())
   manager.reset_sound(Sounds.SOUND_CONSTANTS[sound_name])
  else:
   AudioManager.reset_sound(Sounds.SOUND_CONSTANTS[sound_name])


func play_sound(sound_data: Variant, pitch_scale: float = -1.0, volume: = 1.0, bus: = "Sound") -> AudioManagerSingleton.SoundPlayback:
 if sound_disabled:
  return

 var manager: AudioManagerSingleton
 if Engine.is_editor_hint():
  if not anim_player.is_playing():
   return

  manager = AudioManagerSingleton.get_temporary_audio_manager(get_tree())
 else:
  manager = AudioManager

 if pitch_scale == -1.0:
  if sound_data is Dictionary and "IGNORE_SPRITE_PITCH" in sound_data:
   pitch_scale = 1.0
  else:
   pitch_scale = global_pitch_scale

 return manager.play_sound(sound_data, pitch_scale, volume, bus, self)


func handle_sound(sound_name: String) -> void :
 if sound_disabled:
  return

 if Engine.is_editor_hint():
  Sounds.refresh_sounds()

 if sound_name in Sounds.SOUND_CONSTANTS:
  play_sound(Sounds.SOUND_CONSTANTS[sound_name])


func handle_sounds(sounds_list: PackedStringArray) -> void :
 for sound_name in sounds_list:
  handle_sound(sound_name)


func handle_event(event_name: String) -> void :
 if event_name == "hit":
  hit.emit()
 elif event_name == "animation_looped":
  animation_looped.emit()
 elif event_name == "appeared":
  appeared.emit()
 else:
  if (event_name == "editor_star" or event_name == "editor_star_small" or event_name == "editor_heart") and anim_player.is_playing() and Engine.is_editor_hint():
   var effect_scene: PackedScene = load("res://source/ui/damage_star.tscn")
   if event_name == "editor_heart":
    effect_scene = load("res://source/ui/heal_heart.tscn")

   var damage_star = effect_scene.instantiate()
   add_child(damage_star)
   damage_star.global_position = hit_marker.global_position
   damage_star.appear(0 if event_name == "editor_star_small" else 10, self is CharacterSprite)

  event_emitted.emit(event_name)


func set_animation_flag(flag_name: String, value: bool) -> void :
 animation_flags[flag_name] = value
 flag_changed.emit(flag_name)


func get_animation_flag(flag_name: String) -> bool:
 if active_sub_sprite != null:
  return active_sub_sprite.animation_flags.get(flag_name, false)
 else:
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


func pend_animation_stopped(anim_name: StringName) -> void :
 await anim_player.pend_animation_stopped(anim_name)


func pend_animation_played(anim_name: StringName) -> void :
 await anim_player.pend_animation_played(anim_name)


func pend_any_animation_played(anim_names: Array[StringName]) -> void :
 await anim_player.pend_any_animation_played(anim_names)


func pend_animation_looped(amount: int = 1) -> void :
 for _i in amount:
  await animation_looped


func get_heart() -> int:
 if not unit_is_enemy:
  return Globals.HEARTS.DEFAULT

 if unit_id in Enemies.HEARTS:
  return Enemies.HEARTS[unit_id]

 var champion_of = Enemies.SHADOWS.find_key(unit_id)
 if champion_of != null and champion_of in Enemies.HEARTS:
  return Enemies.HEARTS[champion_of]

 return Globals.HEARTS.DEFAULT


func get_blood_color() -> Color:
 return Globals.BLOOD_COLORS[get_heart()]


func set_active_sub_sprite(sprite: BattleUnitSprite, change_visibility: bool = true) -> void :
 if change_visibility:
  for sub_sprite in sub_sprites:
   if sub_sprite != sprite:
    sub_sprite.hide()
   else:
    sub_sprite.show()

 if active_sub_sprite != null and is_instance_valid(active_sub_sprite):
  active_sub_sprite.hit.disconnect(hit.emit)
  active_sub_sprite.appeared.disconnect(appeared.emit)
  active_sub_sprite.animation_looped.disconnect(animation_looped.emit)
  active_sub_sprite.event_emitted.disconnect(event_emitted.emit)
  active_sub_sprite.flag_changed.disconnect(flag_changed.emit)

  active_sub_sprite.hovered_on.disconnect(_on_hover_area_mouse_entered)
  active_sub_sprite.hovered_off.disconnect(_on_hover_area_mouse_exited)
  active_sub_sprite.hover_area_input.disconnect(_on_hover_area_input_event)

 active_sub_sprite = sprite

 active_sub_sprite.hit.connect(hit.emit)
 active_sub_sprite.appeared.connect(appeared.emit)
 active_sub_sprite.animation_looped.connect(animation_looped.emit)
 active_sub_sprite.event_emitted.connect(event_emitted.emit)
 active_sub_sprite.flag_changed.connect(flag_changed.emit)

 active_sub_sprite.hovered_on.connect(_on_hover_area_mouse_entered.bind(true))
 active_sub_sprite.hovered_off.connect(_on_hover_area_mouse_exited.bind(true))
 active_sub_sprite.hover_area_input.connect(_on_hover_area_input_event.bind(true))
 active_sprite_changed.emit()

 update_hovering()


func update_hovering() -> void :
 var should_be_hovered: = Util.point_in_collision_object(hover_area, InputManager.mouse_position)
 if should_be_hovered != is_hovered:
  is_hovered = should_be_hovered
  if is_hovered:
   hovered_on.emit()
  else:
   hovered_off.emit()


func _on_hover_area_mouse_entered(from_sub_sprite: = false) -> void :
 if active_sub_sprite == null or from_sub_sprite or not is_instance_valid(active_sub_sprite):
  is_hovered = true
  hovered_on.emit()


func _on_hover_area_mouse_exited(from_sub_sprite: = false) -> void :
 if active_sub_sprite == null or from_sub_sprite or not is_instance_valid(active_sub_sprite):
  is_hovered = false
  hovered_off.emit()


func _on_hover_area_input_event(viewport: Node, input_event: InputEvent, shape_idx: int, from_sub_sprite: = false) -> void :
 if active_sub_sprite == null or from_sub_sprite or not is_instance_valid(active_sub_sprite):
  hover_area_input.emit(viewport, input_event, shape_idx)


func get_phonebook_portrait_size() -> Vector2:
 var portrait_control: Control = get_node_or_null("PhonebookPortrait")
 if portrait_control != null:
  return portrait_control.size
 else:
  return Vector2(216, 140)


func prep_phonebook_portrait() -> void :
 var portrait_control = get_node_or_null("PhonebookPortrait")
 if portrait_control != null:
  position = - portrait_control.position

 if unit_id in Enemies.PHONEBOOK_IDLE_OVERRIDE:
  anim_player.play_advance(Enemies.PHONEBOOK_IDLE_OVERRIDE[unit_id])

 initial_phonebook_animation = anim_player.current_animation


func prep_credits() -> void :
 if unit_id in Enemies.PHONEBOOK_IDLE_OVERRIDE:
  anim_player.play_advance(Enemies.PHONEBOOK_IDLE_OVERRIDE[unit_id])

 initial_phonebook_animation = anim_player.current_animation


func copy_sprite_state(other: BattleUnitSprite):
 if (
   not other.anim_player.is_playing()
   or not anim_player.has_animation(other.anim_player.current_animation)
 ):
  return

 if other.anim_player.current_animation != initial_phonebook_animation:
  var animations: = Enemies.get_phonebook_animations(unit_id)
  if other.playing_phonebook_animation not in animations:
   return
  else:
   playing_phonebook_animation = other.playing_phonebook_animation

 var other_sound_playbacks: Array[AudioManagerSingleton.SoundPlayback] = AudioManager.get_node_sounds(other)
 for playback in other_sound_playbacks:
  playback.node = self

 var temp_disabling_sound: = false
 if not sound_disabled:
  temp_disabling_sound = true
  sound_disabled = true

 anim_player.play_advance(other.anim_player.current_animation)
 anim_player.seek(other.anim_player.current_animation_position, true)

 if temp_disabling_sound:
  sound_disabled = false

 for queued in other.anim_player.get_queue():
  anim_player.queue(queued)


func get_phonebook_idle_animation() -> String:
 return initial_phonebook_animation


func has_phonebook_idle_animation() -> bool:
 var idle_animation: = get_phonebook_idle_animation()
 return idle_animation != "" and anim_player.has_animation(idle_animation)


func advance_phonebook_animation() -> void :
 var animations: = Enemies.get_phonebook_animations(unit_id)
 if animations.is_empty():
  return

 var animation_index: int = 0
 if playing_phonebook_animation in animations:
  animation_index = animations.find(playing_phonebook_animation) + 1

 if anim_player.has_animation("RESET"):
  anim_player.play_advance("RESET")

 animation_index = posmod(animation_index, animations.size())
 var animation: Variant = animations[animation_index]
 playing_phonebook_animation = animation
 play_phonebook_animation(animation)


func play_phonebook_animation(animation: Variant, queue: = false, queue_idle: = true) -> void :
 if animation is String:
  if anim_player.has_animation(animation):
   if queue:
    anim_player.queue(animation)
   else:
    anim_player.play_advance(animation)
 elif animation is Array:
  var queuing: = false
  for sub_animation in animation:
   play_phonebook_animation(sub_animation, queuing, false)
   queuing = true
 elif animation is Dictionary:
  if "no_idle" in animation:
   queue_idle = false

  if "animations" in animation:
   play_phonebook_animation(animation.animations, false, false)
  elif "animation" in animation:
   play_phonebook_animation(animation.animation, false, false)

 if queue_idle and has_phonebook_idle_animation():
  anim_player.queue(get_phonebook_idle_animation())


func spawn_speech_bubble() -> SpeechBubble:
 var bubble_scene: PackedScene = load("res://source/ui/speech_bubble.tscn")
 var bubble: SpeechBubble = bubble_scene.instantiate()
 Game.main.add_child(bubble)
 bubble.global_position = %SpeechBubbleMarker.global_position
 return bubble
