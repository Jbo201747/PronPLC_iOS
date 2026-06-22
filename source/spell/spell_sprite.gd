class_name SpellSprite extends Marker2D

const DEFAULT_SHADER_PROPERTIES = {
 recolor_active = false
}

const TWELVE_GAUGE_CLAY_SHADER_PROPERTIES = {
 recolor_active = true, 
 recolor_dark_active = true, 
 recolor = Color(2527962879), 
 recolor_dark = Color(623715327), 
 recolor_brightness = 0.0, 
 recolor_contrast = 1.1, 
}

const CENSORED_SHADER_PROPERTIES = {
 recolor_active = true, 
 recolor = Color(255), 
}

const CENSORED_TEXTURE: Texture2D = preload("res://arte/spells/replacement_character.png")

@export var outline_when_charged: bool = false
@export var animated: bool = false

var spell: Spell = null
var censored: bool = false

@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimPlayer


func _ready() -> void :
 for child in get_children():
  if child is ShadowCloner:
   child.reparent(sprite)
   child._setup_parent()


func link_spell(_spell: Spell) -> void :
 unlink_spell()

 spell = _spell

 anim_player.play("RESET")
 anim_player.advance(0)

 spell.frame_updated.connect(update_frame)
 if outline_when_charged:
  spell.charge_updated.connect(_on_spell_charge_updated)
  spell.curse_updated.connect(_on_spell_charge_updated)
  _on_spell_charge_updated()

 if animated:
  spell.shake.connect(shake)
  spell.animate_charge.connect(charge)
  spell.stop_blinking.connect(stop_blinking)

 spell.shader_state_updated.connect(_on_spell_shader_state_updated)
 _on_spell_shader_state_updated()

 update_texture()


func unlink_spell() -> void :
 if spell == null:
  return
 elif not is_instance_valid(spell):
  spell = null
  return

 Util.disconnect_signal(spell.frame_updated, update_frame)
 Util.disconnect_signal(spell.charge_updated, _on_spell_charge_updated)
 Util.disconnect_signal(spell.curse_updated, _on_spell_charge_updated)

 Util.disconnect_signal(spell.shake, shake)
 Util.disconnect_signal(spell.animate_charge, charge)
 Util.disconnect_signal(spell.stop_blinking, stop_blinking)

 Util.disconnect_signal(spell.shader_state_updated, _on_spell_shader_state_updated)

 spell = null


func set_censored(_censored: bool) -> void :
 censored = _censored
 update_texture()
 _on_spell_shader_state_updated()


func update_texture() -> void :
 if censored:
  sprite.texture = CENSORED_TEXTURE
 else:
  sprite.texture = spell.get_texture()

 update_frame()


func update_frame() -> void :
 if censored:
  sprite.hframes = 1
  sprite.vframes = 1
  sprite.frame = 0
 else:
  var hv_frames: = spell.get_hv_frames()
  sprite.hframes = hv_frames.x
  sprite.vframes = hv_frames.y
  sprite.frame = spell.get_frame()

 update_shader_frame_data()


func update_shader_frame_data() -> void :
 var texture_dimensions = sprite.texture.get_size()
 var frame_size = Vector2i(texture_dimensions.x / sprite.hframes, texture_dimensions.y / sprite.vframes)
 var frame_coord = sprite.frame_coords * frame_size
 sprite.set_instance_shader_parameter("frame_data", Vector4i(frame_coord.x - 1, frame_coord.y - 1, frame_size.x, frame_size.y))


func play_queue_blinking(anim_name: String) -> void :
 var queue_animation: String = ""
 if anim_player.current_animation in ["blink_warning", "flash_shiny"]:
  queue_animation = anim_player.current_animation

 anim_player.play(anim_name)

 if queue_animation != "":
  anim_player.queue(queue_animation)


func charge() -> void :
 play_queue_blinking("charge")



func blink_warning() -> void :
 if "blink_warning" in anim_player.get_queue():
  return

 anim_player.play("blink_warning")


func flash_shiny() -> void :
 if "flash_shiny" in anim_player.get_queue():
  return

 anim_player.play("flash_shiny")


func shake() -> void :
 play_queue_blinking("shake")


func stop_blinking() -> void :
 if anim_player.is_playing() and anim_player.current_animation in ["blink_warning", "flash_shiny"]:
  anim_player.play("RESET")
  anim_player.advance(0)


func _on_spell_charge_updated() -> void :
 sprite.set_instance_shader_parameter("outline_active", spell.has_usable_charge())
 if spell.is_cursed():
  sprite.set_instance_shader_parameter("outline_color", Color(3249209343).linear_to_srgb())
 else:
  sprite.set_instance_shader_parameter("outline_color", Color.WHITE)


func _on_spell_shader_state_updated() -> void :
 var is_censored = spell.id != Globals.SPELLS.REPLACEMENT_CHARACTER and spell.has_curse(Globals.SPELL_CURSES.CENSORED) and not censored
 var properties = DEFAULT_SHADER_PROPERTIES.duplicate()
 if is_censored:
  properties = CENSORED_SHADER_PROPERTIES.duplicate()
 elif spell.is_clay:
  properties = TWELVE_GAUGE_CLAY_SHADER_PROPERTIES.duplicate()

 if not is_censored:
  properties.sepia_active = spell.has_curse(Globals.SPELL_CURSES.NOSTALGIC)
  properties.hsv_active = spell.id == Globals.SPELLS.SSN
  if properties.hsv_active:
   properties.hue_offset = spell.hue_offset
   properties.saturation_offset = spell.saturation_offset

 for param in properties:
  var property: Variant = properties[param]
  if property is Color:
   sprite.set_instance_shader_parameter(param, property.linear_to_srgb())
  else:
   sprite.set_instance_shader_parameter(param, property)
