@tool
class_name MenuTooltip extends Tooltip

const WHITE_FLAGELLUM = preload("res://arte/ui/small_tooltip_flagellum.png")
const RED_FLAGELLUM = preload("res://arte/ui/small_tooltip_flagellum_red.png")

@export var red: bool = false:
 set(value):
  if red != value:
   red = value
   if is_node_ready():
    update_texture()

var text: String:
 set(value):
  if text_playback != null and text_playback.valid:
   text_playback.cancel()

  text = value
  %Label.text = text
  %Label.visible_characters = -1

var text_playback: Util.TypeTextPlayback

@onready var panel: Panel = %Panel
@onready var flagellum: Control = %Flagellum
@onready var sprite: Sprite2D = %Sprite2D


func _ready() -> void :
 update_texture()


func display() -> void :
 var length = len( %Label.text)
 %Label.visible_characters = maxi(length - 12, 0)
 text_playback = Util.type_text_cancelable( %Label, 0.0123, 1, length - %Label.visible_characters, Callable(), true)


func update_texture() -> void :
 if red:
  sprite.texture = RED_FLAGELLUM
  panel.theme_type_variation = "MenuTooltipPanelRed"
 else:
  sprite.texture = WHITE_FLAGELLUM
  panel.theme_type_variation = "MenuTooltipPanel"


func set_alignment(halign: TooltipCollision.TooltipHorizontalAlignment, valign: TooltipCollision.TooltipVerticalAlignment) -> void :
 if valign == TooltipCollision.TooltipVerticalAlignment.TOP:
  flagellum.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
  sprite.position = Vector2(-3.5, -2)
  sprite.frame = 0
  sprite.flip_v = false
 elif valign == TooltipCollision.TooltipVerticalAlignment.BOTTOM:
  flagellum.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
  sprite.position = Vector2(-3.5, -5)
  sprite.frame = 0
  sprite.flip_v = true
 elif halign == TooltipCollision.TooltipHorizontalAlignment.LEFT:
  flagellum.set_anchors_preset(Control.PRESET_CENTER_RIGHT, true)
  sprite.position = Vector2(-2, -3.5)
  sprite.frame = 1
  sprite.flip_h = false
 elif halign == TooltipCollision.TooltipHorizontalAlignment.RIGHT:
  flagellum.set_anchors_preset(Control.PRESET_CENTER_LEFT, true)
  sprite.position = Vector2(-5, -3.5)
  sprite.frame = 1
  sprite.flip_h = true

 add_theme_constant_override("margin_bottom", 3 if valign == TooltipCollision.TooltipVerticalAlignment.TOP else 0)
 add_theme_constant_override("margin_top", 3 if valign == TooltipCollision.TooltipVerticalAlignment.BOTTOM else 0)
 add_theme_constant_override("margin_left", 3 if halign == TooltipCollision.TooltipHorizontalAlignment.RIGHT else 0)
 add_theme_constant_override("margin_right", 3 if halign == TooltipCollision.TooltipHorizontalAlignment.LEFT else 0)
