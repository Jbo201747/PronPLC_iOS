class_name SubTooltip extends MarginContainer


const tile_control_scene: PackedScene = preload("res://source/ui/generic/tile_control.tscn")


var title_length = 1
var tile = null


func display():
 var length = len( %Title.text)
 %Title.visible_characters = maxi(length - 8, 0)
 Util.type_text( %Title, 0.0123, 1, length - %Title.visible_characters)


func set_title(title):
 title_length = len(title)
 var title_label: Label = %Title
 title_label.text = title
 Util.shrink_label_to_bounds(title_label, 92.0)


func set_title_color(color: Color):
 %Title.add_theme_color_override(&"font_color", color)


func set_description(description):
 %Description.text = description
 %Description.visible = description != ""


func set_tile_description(description: String) -> void :
 %TileDescription.text = description
 %TileDescription.visible = description != ""


func add_tile(new_tile: Tile) -> void :
 var tile_control: TileControl = tile_control_scene.instantiate()
 %TileContainer.add_child(tile_control)
 tile_control.set_tile(new_tile)
 %TileContainer.visible = true

 if %TileContainer.get_child_count() > 2:
  %TileContainer.add_theme_constant_override("separation", 0)


func set_tile(to):
 tile = to
 add_tile(tile)


func get_tile():
 return tile
