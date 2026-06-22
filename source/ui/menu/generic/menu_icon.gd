@tool
class_name MenuIcon extends Control


@export var texture: Texture2D:
 set(value):
  texture = value
  %Sprite2D.texture = texture
@export var hv_frames: Vector2i = Vector2i.ONE:
 set(value):
  hv_frames = value
  %Sprite2D.hframes = hv_frames.x
  %Sprite2D.vframes = hv_frames.y
@export var frame: int = 0:
 set(value):
  frame = value
  %Sprite2D.frame = frame
@export var string_identifier: String = "":
 set(value):
  string_identifier = value
  %MenuTooltipCollision.string_identifier = string_identifier
@export var context: Dictionary = {}:
 set(value):
  context = value
  %MenuTooltipCollision.context = context
@export var tooltip_position_offset: Vector2 = Vector2(0.0, -4):
 set(value):
  tooltip_position_offset = value
  %MenuTooltipCollision.position_offset = tooltip_position_offset
@export var tooltip_horizontal_alignment: TooltipCollision.TooltipHorizontalAlignment = TooltipCollision.TooltipHorizontalAlignment.CENTER:
 set(value):
  tooltip_horizontal_alignment = value
  %MenuTooltipCollision.horizontal_alignment = tooltip_horizontal_alignment
@export var tooltip_vertical_alignment: TooltipCollision.TooltipVerticalAlignment = TooltipCollision.TooltipVerticalAlignment.TOP:
 set(value):
  tooltip_vertical_alignment = value
  %MenuTooltipCollision.vertical_alignment = tooltip_vertical_alignment
@export var shadow_offset: Vector2 = Vector2(1, 1):
 set(value):
  shadow_offset = value
  %ShadowCloner.position = shadow_offset


func _ready() -> void :
 resized.connect(update_sprite_offset)
 update_sprite_offset()


func update_sprite_offset() -> void :
 %Sprite2D.offset = size / 2
