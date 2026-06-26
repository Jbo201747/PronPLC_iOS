class_name TileCollision extends Control

signal clicked
signal selected_position_changed
signal selected_region_changed

enum Region{
 LEFT, 
 RIGHT, 
 CENTER, 
 TOP, 
 BOTTOM, 
 NONE
}

const REGION_FRAMES_WITH_CENTER = {
 Region.LEFT: 0, 
 Region.RIGHT: 2, 
 Region.TOP: 5, 
 Region.BOTTOM: 7, 
}

const REGION_FRAMES_WITHOUT_CENTER = {
 Region.LEFT: 3, 
 Region.RIGHT: 4, 
 Region.TOP: 8, 
 Region.BOTTOM: 9, 
}

const CENTER_FRAME_HORIZONTAL = 1
const CENTER_FRAME_VERTICAL = 6

var is_pressed: = false
var has_mouse: = false
var base_size: Vector2
var selected_position: Vector2:
 set(value):
  if selected_position != value:
   selected_position = value
   update_selected_region()
   selected_position_changed.emit()
var selected_region: Region = Region.NONE
var last_selected_region: Region = Region.NONE
@onready var tile: Tile = get_parent()


func _ready() -> void :
 tile.ready.connect(_on_tile_ready)

 if tile.is_preview or not Game.is_in_run():
  return

 base_size = size
 selected_position = size / 2

 Game.main.game_state_updated.connect(_on_game_state_updated)
 focus_entered.connect(_focus_entered)
 focus_exited.connect(_focus_exited)
 mouse_entered.connect(_mouse_entered)
 mouse_exited.connect(_mouse_exited)


func _on_tile_ready() -> void :
 if tile.is_preview:
  set_focus_enabled(false)
  tile.hover_handler.stop()
  return

 tile.hover_handler.hover_condition = func(): return tile.word_holder_hovered
 tile.hover_handler.pressed_condition = func(): return is_pressed


func _gui_input(event: InputEvent) -> void :
 if get_viewport().gui_get_focus_owner() is LineEdit:
  return

 if not tile.is_clickable():
  return

 if event is InputEventMouse:
  selected_position = event.position.clamp(Vector2.ZERO, base_size)

 if Bridge.is_debug_build():
  if event.is_action_pressed("debug_remove_face"):
   var face_duplicate = tile.faces.duplicate()
   face_duplicate.remove_at(tile.tile_face.face_index)
   tile.set_face(face_duplicate)
   accept_event()
   return
  elif event.is_action_pressed("debug_remove_tile"):
   Game.tile_board.remove_tile(tile, {ignore_status = true})
   accept_event()
   return
  elif event.is_action_pressed("debug_paint_status") and Game.debug_painting_status != null:
   if Game.debug_painting_status == "type":
    tile.set_type(Globals.TileType.DAMAGE if tile.type == Globals.TileType.DEFENSE else Globals.TileType.DEFENSE)
   elif Game.debug_painting_status == Globals.TileStatus.LINKED:
    tile.add_status(Globals.TileStatus.LINKED, Globals.LinkColor.values().pick_random())
   elif Game.debug_painting_status == Globals.TileStatus.BOMB:
    tile.add_status(Globals.TileStatus.BOMB, randi_range(1, 3))
   else:
    tile.add_status(Game.debug_painting_status)

   accept_event()
   return
  elif event.is_action_pressed("debug_add_face"):
   tile._debug_edit_face(true)
   accept_event()
   return
  elif event.is_action_pressed("debug_edit_face"):
   tile._debug_edit_face(false)
   accept_event()
   return

 if Input.is_action_just_pressed("click_tile"):
  AudioManager.play_sound(Sounds.UI.TILE_CLICK)
  is_pressed = true
  tile.hover_handler.hover_for_state()
 elif event.is_action_released("click_tile") and is_pressed:
  is_pressed = false
  tile.hover_handler.hover_for_state()
  var allow_click: = Util.is_mobile() or ( not InputManager.is_mouse_mode() or has_mouse) or has_focus(true)
  if allow_click:
   if not tile.click_tile():
    tile.play_tile_sound()


func get_selected_position(center: = true) -> Vector2:
 if center:
  return selected_position - size / 2.0
 else:
  return selected_position


func can_grab_focus() -> bool:
 return focus_mode == Control.FOCUS_ALL


func can_release_focus() -> bool:
 return not is_pressed and tile.state != Tile.State.DRAGGING


func set_focus_enabled(enabled: bool) -> void :
 if enabled:
  focus_mode = Control.FOCUS_ALL
  if InputManager.is_mouse_mode():
   if has_mouse:
    if get_global_rect().has_point(InputManager.get_mouse_position()):
     grab_focus(true)
    else:
     has_mouse = false
 else:
  focus_mode = Control.FOCUS_NONE


func update_hover_handler_enabled() -> void :
 if tile.state == Tile.State.DRAGGING:
  tile.hover_handler.stop()
 elif tile.word_holder_hovered or tile.is_hoverable():
  tile.hover_handler.resume()
 else:
  tile.hover_handler.stop()


func update_focus_enabled() -> void :
 if tile.state == Tile.State.DRAGGING:
  set_focus_enabled(true)
  if not has_focus():
   grab_focus(true)
 elif tile.is_hoverable():
  set_focus_enabled(true)
 else:
  set_focus_enabled(false)


func get_selected_region(selectable_regions: Array[Region]) -> Region:
 var selected_pos: = get_selected_position()
 if Region.CENTER in selectable_regions:
  var is_center_selected = true
  if Region.LEFT in selectable_regions and selected_pos.x < -5:
   is_center_selected = false
  elif Region.RIGHT in selectable_regions and selected_pos.x > 5:
   is_center_selected = false

  if Region.TOP in selectable_regions and selected_pos.y < -5:
   is_center_selected = false
  elif Region.BOTTOM in selectable_regions and selected_pos.y > 5:
   is_center_selected = false

  if is_center_selected:
   return Region.CENTER

 var check_left_right: = true
 if Region.TOP in selectable_regions and selected_pos.y < -5:
  check_left_right = false
 elif Region.BOTTOM in selectable_regions and selected_pos.y > 5:
  check_left_right = false

 if check_left_right:
  if selected_pos.x < 0:
   return Region.LEFT
  elif selected_pos.x > 0:
   return Region.RIGHT
  else:
   return Region.RIGHT
 else:
  if selected_pos.y < 0:
   return Region.TOP
  elif selected_pos.y > 0:
   return Region.BOTTOM
  else:
   return Region.BOTTOM


func update_selected_region() -> void :
 var selectable_regions: Array[Region] = []
 var prev_selected_region: Region = selected_region
 if Game.player.is_using_modifier_spell(true) and has_focus():
  var using_spell: TileModifierSpell = Game.player.get_using_spell() as TileModifierSpell
  selectable_regions = using_spell.get_selectable_tile_regions()
  selected_region = get_selected_region(selectable_regions)
 else:
  selected_region = Region.NONE

 if selected_region != Region.NONE:
  last_selected_region = selected_region

 if selected_region != prev_selected_region:
  tile.tile_sprite.region_overlay.visible = selected_region != Region.NONE and not selectable_regions.is_empty()
  if not selectable_regions.is_empty():
   if selected_region == Region.CENTER:
    if Region.TOP in selectable_regions or Region.BOTTOM in selectable_regions:
     tile.tile_sprite.region_overlay.frame = CENTER_FRAME_VERTICAL
    else:
     tile.tile_sprite.region_overlay.frame = CENTER_FRAME_HORIZONTAL
   elif Region.CENTER in selectable_regions:
    tile.tile_sprite.region_overlay.frame = REGION_FRAMES_WITH_CENTER[selected_region]
   else:
    tile.tile_sprite.region_overlay.frame = REGION_FRAMES_WITHOUT_CENTER[selected_region]

  selected_region_changed.emit()


func _on_game_state_updated() -> void :
 update_hover_handler_enabled()
 update_focus_enabled()


func _focus_entered() -> void :
 update_selected_region()
 Game.tile_selected.emit()


func _focus_exited() -> void :
 update_selected_region()
 Game.tile_deselected.emit()
 is_pressed = false


func _mouse_entered() -> void :
 has_mouse = true


func _mouse_exited() -> void :
 has_mouse = false
