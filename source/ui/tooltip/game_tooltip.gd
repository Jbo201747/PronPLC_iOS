class_name GameTooltip extends Tooltip


const sub_tooltip_scene: PackedScene = preload("res://source/ui/tooltip/sub_tooltip.tscn")
const mega_tooltip_scene: PackedScene = preload("res://source/ui/tooltip/mega_tooltip.tscn")

var subtooltips = []

@onready var container = %SubtooltipContainer
@onready var dotted_line_box: DottedLineBox = %DottedLineBox
@onready var alternating_page_box: AlternatingPageBox = %AlternatingPageBox


func reset():
 for child in container.get_children():
  child.queue_free()


func add_subtooltip(title, description: = "", tile = null, tile_description: = ""):
 var subtooltip: SubTooltip = sub_tooltip_scene.instantiate()
 if tile != null:
  if tile is Array:
   for new_tile in tile:
    subtooltip.add_tile(new_tile)
  else:
   subtooltip.set_tile(tile)

 subtooltip.set_title(title)
 subtooltip.set_description(description)
 subtooltip.set_tile_description(tile_description)
 container.add_child(subtooltip)
 subtooltips.append(subtooltip)
 return subtooltip


func add_mega_tooltip(description: String) -> void :
 var mega_tooltip = mega_tooltip_scene.instantiate()
 mega_tooltip.set_description(description)
 container.add_child(mega_tooltip)
 subtooltips.append(mega_tooltip)


func get_preview_tile():
 for subtooltip in subtooltips:
  if subtooltip.get_tile() != null:
   return subtooltip.get_tile()


func display():
 for subtooltip in subtooltips:
  subtooltip.display()


func update_panels() -> void :
 dotted_line_box.update_panels()
 alternating_page_box.update_panels()


func _on_subtooltip_container_sort_children() -> void :
 reset_size()
 update_panels()
