class_name TileSlot extends Node2D

var multiplier: int

@onready var sprite: Sprite2D = %Sprite2D
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var label: DebossLabel = %Label


func set_multiplier(_multiplier: int) -> void :
 multiplier = _multiplier
 if multiplier == -99:
  sprite.frame = 5
 elif multiplier == -1:
  sprite.frame = 3
 elif multiplier == -2:
  sprite.frame = 4
 else:
  sprite.frame = multiplier - 1

 label.visible = multiplier != 1 and multiplier != -99
 if label.visible:
  if multiplier == -1:
   label.text = "-"
  elif multiplier == -2:
   label.text = "--"
  else:
   label.text = "x" + str(multiplier)


func appear(instant: = false) -> void :
 await anim_player.play_until_finished("appear", instant)


func disappear(instant: = false, free_on_disappear: = false) -> void :
 await anim_player.play_until_finished("disappear", instant)
 if free_on_disappear:
  queue_free()


func _on_tooltip_collision_generate_tooltip(tooltip: Variant) -> void :
 var context = {spiked = multiplier == -99, negative = multiplier != -99 and multiplier < 0, multiplier = multiplier}

 tooltip.add_subtooltip(
  StringManager.get_string("misc/tile_slot/title", context), 
  StringManager.get_string("misc/tile_slot/description", context)
 )


func _on_tooltip_collision_check_generate_tooltip(tooltip_collision: Variant) -> void :
 if anim_player.is_playing() or anim_player.assigned_animation == "disappear" or Tile.get_focused_tile() != null:
  tooltip_collision.enabled = false
 else:
  tooltip_collision.enabled = true
