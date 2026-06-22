@tool
class_name DebossLabel extends Control


@export var text: String = "":
 set(value):
  text = value
  update_minimum_size()
  queue_redraw()

@export_group("Font")
@export var font: Font:
 set(value):
  font = value
  update_minimum_size()
  queue_redraw()
@export var font_size: int = 10:
 set(value):
  font_size = value
  update_minimum_size()
  queue_redraw()
@export var color: = Color.BLACK:
 set(value):
  color = value
  queue_redraw()

@export_group("Deboss")
@export var deboss_enabled: = true:
 set(value):
  deboss_enabled = value
  queue_redraw()
@export var deboss_color: = Color.WHITE:
 set(value):
  deboss_color = value
  queue_redraw()

@export_group("Outline")
@export var outline_size: = -1:
 set(value):
  outline_size = value
  queue_redraw()
@export var outline_color: = Color.WHITE:
 set(value):
  outline_color = value
  queue_redraw()

var text_line = TightTextLine.new()


func _ready() -> void :
 if not Engine.is_editor_hint():
  mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
 text_line.clear()
 text_line.add_string(text, font, font_size)
 return text_line.get_tight_rect().size


func _draw():
 text_line.clear()
 text_line.add_string(text, font, font_size)

 var tight_rect = text_line.get_tight_rect()
 var pos = ( - tight_rect.size / 2.0) - tight_rect.position + size / 2

 if deboss_enabled:
  text_line.draw(get_canvas_item(), pos + Vector2(0, 0.5), deboss_color)

 if outline_size != -1:
  text_line.draw_outline(get_canvas_item(), pos, outline_size, outline_color)

 text_line.draw(get_canvas_item(), pos, color)
