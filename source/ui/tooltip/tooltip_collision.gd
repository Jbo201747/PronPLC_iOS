class_name TooltipCollision extends Control


signal hovered_on
signal hovered_off
signal generate_tooltip(tooltip)
signal check_generate_tooltip(tooltip_collision)

enum TooltipHorizontalAlignment{
 LEFT, 
 CENTER, 
 RIGHT, 
}

enum TooltipVerticalAlignment{
 TOP, 
 CENTER, 
 BOTTOM, 
}

static var active_tooltip = null

@export var default_delay = 30
@export var horizontal_alignment: TooltipHorizontalAlignment = TooltipHorizontalAlignment.CENTER
@export var vertical_alignment: TooltipVerticalAlignment = TooltipVerticalAlignment.TOP
@export var position_offset: Vector2 = Vector2.ZERO
@export var active_with_spells: bool = false
@export var menu_tooltip: = false
@export var focus_source: Control

@export var allow_fallback: = false
@export var fallback_halign: TooltipHorizontalAlignment = TooltipHorizontalAlignment.RIGHT
@export var fallback_valign: TooltipVerticalAlignment = TooltipVerticalAlignment.CENTER
@export var fallback_position_offset: Vector2 = Vector2.ZERO

@export var tooltip_scene: PackedScene = preload("res://source/ui/tooltip/game_tooltip.tscn")

var tooltip = null

var description = null
var tooltip_delay = default_delay
var max_delay = default_delay:
 set(value):
  max_delay = value
  tooltip_delay = min(tooltip_delay, max_delay)
var was_hovered = false
var is_displaying = false
var enabled = true

@onready var main = Game.main


func _ready():
 tooltip_delay = default_delay
 max_delay = default_delay
 set_process(false)
 if focus_source != null:
  focus_source.focus_entered.connect(check_hovering)
  focus_source.focus_exited.connect(check_hovering)
 elif menu_tooltip or Game.is_in_run():
  InputManager.mouse_position_changed.connect(check_hovering)

 if Game.is_in_run():
  Game.main.game_state_updated.connect(check_hovering)


func _process(delta):
 check_hovering()
 if was_hovered:
  if tooltip_delay > 0:
   tooltip_delay -= 60 * delta

  elif not is_displaying:
   display_tooltip()


func _exit_tree():
 if is_displaying:
  clear_tooltip()


func is_hovered() -> bool:
 if not menu_tooltip and not Game.is_in_run():
  return false

 if active_tooltip != null and is_instance_valid(active_tooltip) and active_tooltip != self:
  return false

 if not is_visible_in_tree():
  return false

 if not (
  menu_tooltip
  or main.is_game_actionable(true, false, true)
  or (Game.player.is_using_spell() and active_with_spells)
 ):
  return false

 if focus_source != null:
  return focus_source.has_focus()
 else:
  return get_global_rect().has_point(InputManager.get_mouse_position())


func check_hovering():
 if is_queued_for_deletion():
  return

 var hovered = is_hovered()
 if hovered != was_hovered:
  was_hovered = hovered
  set_process(hovered)
  if hovered:
   hovered_on.emit()
  else:
   hovered_off.emit()
   tooltip_delay = max_delay

   if is_displaying:
    clear_tooltip()


func display_tooltip():
 check_generate_tooltip.emit(self)
 if not enabled:
  return

 var parent_node: Node = null
 if menu_tooltip:
  parent_node = get_tree().get_first_node_in_group("menu_tooltips_parent")
 else:
  parent_node = get_tree().get_first_node_in_group("game_tooltips_parent")

 if parent_node == null:
  return

 tooltip = tooltip_scene.instantiate()

 parent_node.add_child(tooltip)

 populate_tooltip()

 reposition_tooltip()
 tooltip.resized.connect(reposition_tooltip)
 tooltip.minimum_size_changed.connect(reposition_tooltip)

 tooltip.display()

 active_tooltip = self
 is_displaying = true


func populate_tooltip() -> void :
 generate_tooltip.emit(tooltip)


func reposition_tooltip():
 position_tooltip_for_alignment(horizontal_alignment, vertical_alignment, position_offset)

 if allow_fallback and not tooltip_in_bounds():
  position_tooltip_for_alignment(fallback_halign, fallback_valign, fallback_position_offset)


func tooltip_in_bounds(check_horizontal: bool = true, check_vertical: bool = true) -> bool:
 var tooltip_bottom_right = tooltip.global_position + tooltip.size
 if check_vertical:
  if tooltip.global_position.y < 4 or tooltip_bottom_right.y > (270 - 4):
   return false

 if check_horizontal:
  if tooltip.global_position.x < 4 or tooltip_bottom_right.x > (480 - 4):
   return false

 return true


func position_tooltip_for_alignment(halign: TooltipHorizontalAlignment, valign: TooltipVerticalAlignment, pos_offset: Vector2) -> void :
 var base_offset: = size / 2
 var tooltip_size = tooltip.size

 var x_offset = - tooltip_size.x / 2.0
 var y_offset = - tooltip_size.y / 2.0

 if halign == TooltipHorizontalAlignment.RIGHT:
  base_offset.x = size.x
  x_offset = 0.0
 elif halign == TooltipHorizontalAlignment.LEFT:
  base_offset.x = 0.0
  x_offset = - tooltip_size.x

 if valign == TooltipVerticalAlignment.BOTTOM:
  base_offset.y = size.y
  y_offset = 0.0
 elif valign == TooltipVerticalAlignment.TOP:
  base_offset.y = 0.0
  y_offset = - tooltip_size.y

 tooltip.global_position = global_position + base_offset + pos_offset + Vector2(x_offset, y_offset)

 var tooltip_bottom_right = tooltip.global_position + tooltip.size
 if tooltip.global_position.x < 4:
  tooltip.global_position.x = 4
 elif tooltip_bottom_right.x > (480 - 4):
  tooltip.global_position.x -= (tooltip_bottom_right.x - (480 - 4))


func clear_tooltip():
 if not tooltip or not is_instance_valid(tooltip):
  return

 if tooltip.resized.is_connected(reposition_tooltip):
  tooltip.resized.disconnect(reposition_tooltip)
  tooltip.minimum_size_changed.disconnect(reposition_tooltip)

 tooltip.queue_free()

 if active_tooltip == self:
  active_tooltip = null

 tooltip = null
 is_displaying = false


func set_position_offset(vector):
 position_offset = vector
