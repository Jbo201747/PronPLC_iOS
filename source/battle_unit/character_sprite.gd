@tool
class_name CharacterSprite extends BattleUnitSprite

@export var trans_texture: Texture2D
@export var base_texture: Texture2D
@export var alt_trans_texture: Texture2D
@export var alt_base_texture: Texture2D
@export var is_trans: bool = false:
 set(value):
  is_trans = value
  if is_node_ready():
   update_texture()
   update_pitch()

@export var trans_pitch_scale: float = 1.0
@export var base_pitch_scale: float = 1.0

@onready var sprite = $Sprite

@onready var photo_marker: Marker2D = %PhotoMarker
@onready var trans_photo_marker: Marker2D = get_node_or_null("%TransPhotoMarker")
@onready var anvil_marker: Marker2D = %AnvilMarker


func _ready() -> void :
 update_texture()
 update_pitch()


func _notification(what: int) -> void :
 if what == NOTIFICATION_EDITOR_PRE_SAVE:
  sprite.texture = null
  global_pitch_scale = 1.0
 elif what == NOTIFICATION_EDITOR_POST_SAVE:
  update_texture()
  update_pitch()


func update_pitch() -> void :
 if is_trans:
  global_pitch_scale = trans_pitch_scale
 else:
  global_pitch_scale = base_pitch_scale


func update_texture() -> void :
 if is_trans:
  if alt_trans_texture != null and ( not Engine.is_editor_hint() and Game.is_steam_inactive()):
   sprite.texture = alt_trans_texture
  elif trans_texture != null:
   sprite.texture = trans_texture
  else:
   sprite.texture = base_texture
 else:
  if alt_base_texture != null and ( not Engine.is_editor_hint() and Game.is_steam_inactive()):
   sprite.texture = alt_base_texture
  else:
   sprite.texture = base_texture
