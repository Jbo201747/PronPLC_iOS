class_name TightTextLine extends TextLine


func get_tight_rect() -> Rect2:
 var ascent = get_line_ascent()

 var text_server = TextServerManager.get_primary_interface()
 var glyphs = text_server.shaped_text_get_glyphs(get_rid())
 var glyph_x = 0.0
 var tight_rect = Rect2()
 for glyph in glyphs:
  var glyph_font_rid = glyph.get("font_rid", RID())
  var glyph_index = glyph.get("index", -1)
  var glyph_font_size = Vector2i(glyph.get("font_size"), 0)
  var glyph_offset = text_server.font_get_glyph_offset(glyph_font_rid, glyph_font_size, glyph_index)
  var glyph_size = text_server.font_get_glyph_size(glyph_font_rid, glyph_font_size, glyph_index)
  var glyph_rect = Rect2(Vector2(glyph_x, ascent) + glyph_offset, glyph_size)
  if glyph_rect.has_area():
   if not tight_rect.has_area():
    tight_rect = glyph_rect
   else:
    tight_rect.position.x = min(tight_rect.position.x, glyph_rect.position.x)
    tight_rect.position.y = min(tight_rect.position.y, glyph_rect.position.y)
    tight_rect.size.x = max(tight_rect.size.x, glyph_rect.end.x - tight_rect.position.x)
    tight_rect.size.y = max(tight_rect.size.y, glyph_rect.end.y - tight_rect.position.y)

  glyph_x += glyph.get("advance", 0)

 return tight_rect


func fit_space(text: String, font: Font, font_size: int, max_width: int = -1, max_height: int = -1) -> Rect2:
 var tight_rect = Rect2()
 while ( not tight_rect.has_area()
 or (max_width != -1 and tight_rect.size.x > max_width)
 or (max_height != -1 and tight_rect.size.y > max_height)):
  clear()
  add_string(text, font, font_size)
  tight_rect = get_tight_rect()
  font_size -= 1
  if font_size == 0:
   break

 return tight_rect
