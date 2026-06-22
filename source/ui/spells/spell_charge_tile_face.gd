@tool
extends Node2D


const FONT_SIZE = 9
const FONT = preload("res://fonts/Suwannaphum-Regular.ttf")
const FACE_OFFSET = Vector2(0, -1)

@export var face: String = "":
 set(value):
  face = value
  queue_redraw()
var face_text_line = TightTextLine.new()


func _draw():
 face_text_line.clear()
 var face_tight_rect = face_text_line.fit_space(face, FONT, FONT_SIZE, 14, 14)
 var draw_pos = - face_tight_rect.position - face_tight_rect.size / 2
 face_text_line.draw(get_canvas_item(), draw_pos + FACE_OFFSET, Color.BLACK)
