@tool
class_name MenuStat extends HBoxContainer


@export var texture: Texture2D:
 set(value):
  texture = value
  %MenuIcon.texture = texture
@export var hv_frames: Vector2i = Vector2i.ONE:
 set(value):
  hv_frames = value
  %MenuIcon.hv_frames = hv_frames
@export var frame: int = 0:
 set(value):
  frame = value
  %MenuIcon.frame = value
@export var string_identifier: String = "":
 set(value):
  string_identifier = value
  %MenuIcon.string_identifier = string_identifier
@export var context: Dictionary = {}:
 set(value):
  context = value
  %MenuIcon.context = context
@export var stat_text: String = "":
 set(value):
  stat_text = value
  %StatLabel.text = value
