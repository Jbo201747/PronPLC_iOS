class_name RecolorUtil


static func get_colors_from_coordinates(image: Image, source_color_coords: Dictionary[String, Vector2i], offset: Vector2i = Vector2i.ZERO) -> Dictionary[String, Color]:
 var colors: Dictionary[String, Color] = {}
 for key in source_color_coords:
  colors[key] = image.get_pixelv(source_color_coords[key] + offset)

 return colors


static func get_color_coordinate_lists(image: Image, source_color_coords: Dictionary[String, Vector2i], offset: Vector2i = Vector2i.ZERO) -> Dictionary[String, Array]:
 var colors: = get_colors_from_coordinates(image, source_color_coords, offset)
 var color_coordinates: Dictionary[String, Array] = {}
 for x in image.get_width():
  for y in image.get_height():
   var pixel: = image.get_pixelv(Vector2i(x, y) + offset)
   var color_key: Variant = colors.find_key(pixel)
   if color_key != null:
    color_coordinates.get_or_add(color_key, []).append(Vector2i(x, y))

 return color_coordinates


static func recolor(image: Image, color_coord_list: Dictionary[String, Array], colors: Dictionary[String, Color], offset: Vector2i = Vector2i.ZERO) -> void :
 for color_key in color_coord_list:
  var coordinates: = color_coord_list[color_key]
  var color: = colors[color_key]
  for coord: Vector2i in coordinates:
   image.set_pixelv(coord + offset, color)
