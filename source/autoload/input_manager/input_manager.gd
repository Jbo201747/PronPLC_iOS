extends CanvasLayer

signal input_mode_changed
signal mouse_position_changed

signal controller_type_changed

signal ui_pressed(direction: Direction)
signal ui_released(direction: Direction)

enum Direction{
 LEFT, 
 RIGHT, 
 UP, 
 DOWN, 
}

enum InputMode{
 MOUSE, 
 KEYBOARD, 
 CONTROLLER, 
}

enum Controller{
 XBOX, 
 SWITCH, 
 PLAYSTATION, 
 STEAM, 
}

const CONTROLLER_KEYWORDS: Dictionary[Controller, PackedStringArray] = {
 Controller.XBOX: ["Xbox", "XInput"], 
 Controller.PLAYSTATION: ["Sony", "PS3", "PS5", "PS4", "DUALSHOCK 4", "DualSense", "Nacon Revolution Unlimited Pro Controller"], 
 Controller.STEAM: ["Steam"], 
 Controller.SWITCH: ["Switch", "Joy-Con", "PowerA Core Controller"], 
}

const INPUT_GLYPH_FRAMES: Dictionary[int, int] = {
 JoyButton.JOY_BUTTON_A: 0, 
 JoyButton.JOY_BUTTON_B: 1, 
 JoyButton.JOY_BUTTON_X: 2, 
 JoyButton.JOY_BUTTON_Y: 3, 
}

const COMPOSITE_ACTIONS: Dictionary[StringName, Array] = {
 &"any_change_focus": [
  &"ui_left", &"ui_right", &"ui_up", &"ui_down", 
  &"ui_focus_next", &"ui_focus_prev", 
 ], 
 &"any_focus": [
  &"ui_left", &"ui_right", &"ui_up", &"ui_down", 
  &"ui_focus_next", &"ui_focus_prev", &"ui_accept", 
 ], 
}

const SUB_ACTIONS: Dictionary[StringName, Array] = {
 &"ui_accept": [&"ui_accept_menu", &"ui_accept_minigame"], 
 &"ui_up": [&"ui_up_menu"], 
 &"ui_down": [&"ui_down_menu"], 
 &"ui_left": [&"ui_left_menu"], 
 &"ui_right": [&"ui_right_menu"], 
 &"spell_0": [&"spell_0_gamepad", &"spell_0_gamepad_alt"], 
 &"spell_1": [&"spell_1_gamepad", &"spell_1_gamepad_alt"], 
 &"spell_2": [&"spell_2_gamepad", &"spell_2_gamepad_alt"], 
 &"spell_3": [&"spell_3_gamepad", &"spell_3_gamepad_alt"], 
 &"advance_cutscene": [&"ui_accept"]
}

const MENU_ACTIONS: Array[StringName] = [
 &"ui_accept_menu", 
 &"ui_up_menu", &"ui_down_menu", &"ui_left_menu", &"ui_right_menu", 
]

const CONTROLLER_MOUSE_SPEED: float = 6.0

const UI_ACTIONS: Dictionary[Direction, StringName] = {
 Direction.LEFT: &"ui_left", 
 Direction.RIGHT: &"ui_right", 
 Direction.UP: &"ui_up", 
 Direction.DOWN: &"ui_down", 
}

const UI_ECHO_INITIAL_DELAY = 0.5
const UI_ECHO_TIME: float = 1.0 / 20.0

var input_mode: InputMode = InputMode.MOUSE
var controller_type: Controller = Controller.XBOX
var mouse_position: Vector2
var handling_controller_type: = true
var using_controller_mouse: = false
var left_stick_recently_touched: = false
var right_stick_recently_touched: = false
var just_warped: = false
var left_stick_focused_node: Control = null
var mouse_pressed: = false
var using_menu_actions: = false
var window_size_changed_cooldown: = 0.0

var remove_tile_cooldown: float = 0.0
var removing_tiles: = false

var active_joypad: int = -1

var ui_pressed_states: Dictionary[Direction, bool] = {}
var ui_echo_timer: float = 0.0

var action_listeners: Dictionary[StringName, ActionListener] = {}

var disabled_sub_actions: Dictionary[StringName, bool] = {}
var sub_actions_need_updating: = true

var cursor_size: = Vector2i(-1, -1)
var cursor_hotspot: = Vector2i(2, 3)
var mouse_texture: = preload("res://arte/ui/cursor_shadow.png")
var click_texture: = preload("res://arte/ui/cursor_click_shadow.png")

var cursor_images: Array[Image] = [mouse_texture.get_image(), click_texture.get_image()]

@onready var virtual_cursor: VirtualCursor = %VirtualCursor


func _ready() -> void :
 Game.main_scene_loaded.connect(_game_start)

 for direction in Direction.values():
  ui_pressed_states[direction] = false

 set_process(false)
 update_cursor_size()
 get_window().size_changed.connect(_window_size_changed)
 get_window().gui_focus_changed.connect(_gui_focus_changed)
 virtual_cursor.visible = false
 virtual_cursor.visibility_changed.connect(update_mouse_visibility)
 virtual_cursor.position_changed.connect(mouse_position_changed.emit)

 SaveManager.updated_settings.connect(update_actions)
 SaveManager.updated_cursor_scale.connect(update_cursor_size)
 update_actions()

 if Util.is_mobile():
  set_input_mode(InputMode.MOUSE)

 if Bridge.is_debug_build():
  for device in Input.get_connected_joypads():
   print(Input.get_joy_info(device), " ", Input.get_joy_name(device))


func _process(delta: float) -> void :
 var window_focused: = get_window().has_focus()
 if not window_focused:
  for direction in ui_pressed_states:
   if ui_pressed_states[direction]:
    ui_pressed_states[direction] = false
    ui_released.emit(direction)

 var any_ui_currently_pressed: = false
 for direction in ui_pressed_states:
  if ui_pressed_states[direction]:
   if not Input.is_action_pressed(UI_ACTIONS[direction], true):
    ui_pressed_states[direction] = false
    ui_released.emit(direction)
   else:
    any_ui_currently_pressed = true

 ui_echo_timer += delta
 if ui_echo_timer > UI_ECHO_TIME:
  ui_echo_timer -= UI_ECHO_TIME

  for direction in ui_pressed_states:
   if ui_pressed_states[direction]:
    ui_pressed.emit(direction)

 if just_warped:
  just_warped = false

 if window_focused and right_stick_recently_touched:
  update_right_stick()

 if window_focused and left_stick_recently_touched:
  update_left_stick()

 if removing_tiles:
  update_tile_removing(delta)

 if window_size_changed_cooldown > 0.0:
  window_size_changed_cooldown = maxf(window_size_changed_cooldown - delta, 0.0)

 if not (
  left_stick_recently_touched
  or right_stick_recently_touched
  or any_ui_currently_pressed
  or window_size_changed_cooldown > 0.0
  or removing_tiles
 ):
  set_process(false)


func _unhandled_input(event: InputEvent) -> void :
 if not get_window().has_focus():
  return

 var focus_owner: = get_viewport().gui_get_focus_owner()
 if focus_owner is LineEdit:
  if event.is_action_pressed("primary_button"):
   focus_owner.release_focus()

  return

 for action in action_listeners:
  action_listeners[action].handle_input(event)

 if event is InputEventJoypadMotion and get_input_mode() == InputMode.CONTROLLER:
  if absf(event.axis_value) > 0.2:
   if event.is_action("left_stick") and not using_menu_actions:
    left_stick_recently_touched = true
    set_process(true)
   elif event.is_action("right_stick"):
    right_stick_recently_touched = true
    set_process(true)

 if not Game.is_in_run() or Game.main.is_paused() or Game.main.using_dialogue_cutscene_controls():
  return

 var main = Game.main
 var game_menu_active: bool = Game.main.game_menu_controller.is_active()
 var in_spell_select: bool = Game.main.spell_select.active

 if not game_menu_active or in_spell_select:
  for i in 4:
   if event.is_action_pressed("spell_" + str(i)):
    get_viewport().set_input_as_handled()
    focus_spell(i)

  if main.player.is_selecting() and event.is_action_pressed("cancel_selection"):
   main.player.cancel_selection()
   get_viewport().set_input_as_handled()

 if event.is_action_pressed("end_action"):
  var minigame: Minigame = Game.main.get_active_minigame()
  if main.summary_menu.active:
   get_viewport().set_input_as_handled()
   main.summary_menu.continue_button.pressed.emit()
  elif minigame != null:
   get_viewport().set_input_as_handled()
   minigame.confirm()
  elif main.is_game_actionable(true):
   if main.spell_select.active:
    get_viewport().set_input_as_handled()
    main.spell_select._on_skip_button_pressed()
   else:
    if main.submit_button.state != main.submit_button.PENDING:
     get_viewport().set_input_as_handled()
     main.submit_button.press(true)

 if game_menu_active:
  return

 if event.is_action_pressed("select_word") and can_do_left_stick_picking():
  left_stick_recently_touched = true
  set_process(true)

 if event.is_action_pressed("remove_tile") and Input.is_action_just_pressed_by_event("remove_tile", event) and can_do_tile_removing():
  var success: = remove_last_or_selected_tile()
  if success:
   removing_tiles = true
   remove_tile_cooldown = 0.4
   set_process(true)
   get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void :
 if not Util.is_mobile() and not get_window().has_focus():
  return

 if Util.is_mobile() and event is InputEventScreenTouch:
  set_input_mode(InputMode.MOUSE)

 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT:
   if event.is_pressed():
    mouse_pressed = true
    update_cursor_image()
   elif event.is_released():
    mouse_pressed = false
    update_cursor_image()

 if should_regrab_focus(event):
  grab_initial_focus()
  get_viewport().set_input_as_handled()

 var focus_owner: = get_viewport().gui_get_focus_owner()
 if focus_owner is LineEdit:
  return

 if event.is_action_pressed("any_controller"):
  set_input_mode(InputMode.CONTROLLER)

 if event is InputEventMouse and not is_mouse_mode() and is_controller_inactive():
  if event is InputEventMouseMotion:
   if event.relative.length_squared() > 2.0 and window_size_changed_cooldown <= 0.0:
    set_input_mode(InputMode.MOUSE)
  elif event.is_pressed():
   set_input_mode(InputMode.MOUSE)

 if event is InputEventMouse:
  mouse_position = event.global_position
  mouse_position_changed.emit()

 if get_input_mode() == InputMode.CONTROLLER:
  if event is InputEventJoypadButton or event is InputEventJoypadMotion:
   active_joypad = event.device
   if handling_controller_type:
    set_controller_type(get_controller_type_for_device(event.device))
 else:
  active_joypad = -1

 for direction in UI_ACTIONS:
  if Input.is_action_just_pressed_by_event(UI_ACTIONS[direction], event, true):
   ui_echo_timer = - UI_ECHO_INITIAL_DELAY
   ui_pressed_states[direction] = true
   ui_pressed.emit(direction)
   set_process(true)


func get_action_listener(action: StringName) -> ActionListener:
 if action in action_listeners:
  return action_listeners[action]
 else:
  var listener: = ActionListener.new(action)
  action_listeners[action] = listener
  return listener


func any_ui_pressed(directions: Array = Direction.values()) -> bool:
 for direction in directions:
  if ui_pressed_states[direction]:
   return true

 return false


func get_left_stick_vector() -> Vector2:
 return Input.get_vector("left_stick_left", "left_stick_right", "left_stick_up", "left_stick_down")


func get_right_stick_vector() -> Vector2:
 return Input.get_vector("right_stick_left", "right_stick_right", "right_stick_up", "right_stick_down")


func get_any_stick_vector() -> Vector2:
 var left_stick_vector: = get_left_stick_vector()
 var right_stick_vector: = get_right_stick_vector()
 if not left_stick_vector.is_zero_approx():
  return left_stick_vector
 elif not right_stick_vector.is_zero_approx():
  return right_stick_vector
 else:
  return Vector2.ZERO


func get_keyboard_vector() -> Vector2:
 return Input.get_vector("keyboard_left", "keyboard_right", "keyboard_up", "keyboard_down")


func get_any_movement_vector() -> Vector2:
 if input_mode == InputMode.CONTROLLER:
  return get_any_stick_vector()
 else:
  return get_keyboard_vector()


func is_controller_inactive() -> bool:
 return (
  get_left_stick_vector().is_zero_approx()
  and get_right_stick_vector().is_zero_approx()
  and not Input.is_action_pressed("any_controller")
  and not just_warped
 )


func is_mouse_mode() -> bool:
 return get_input_mode() == InputMode.MOUSE


func release_non_mouse_focus() -> void :
 var focus_owner: = get_viewport().gui_get_focus_owner()
 if focus_owner != null and focus_owner.has_focus(true) and can_take_focus():
  focus_owner.release_focus()


func set_input_mode(mode: InputMode) -> void :
 if input_mode == mode:
  return

 input_mode = mode

 if input_mode == InputMode.MOUSE:
  using_controller_mouse = false
  release_non_mouse_focus()

 update_mouse_visibility()


func get_input_mode() -> InputMode:
 return input_mode


func set_controller_type(controller: Controller) -> void :
 controller_type = controller
 controller_type_changed.emit()


func get_controller_type() -> Controller:
 return controller_type


func get_controller_type_for_device(device: int) -> Controller:
 var info: = Input.get_joy_info(device)
 var raw_name: String = info.raw_name
 for controller in CONTROLLER_KEYWORDS:
  var keywords = CONTROLLER_KEYWORDS[controller]
  for keyword in keywords:
   if keyword.to_lower() in raw_name.to_lower():
    return controller

 return Controller.XBOX


func update_mouse_visibility() -> void :
 if virtual_cursor.visible or ( not is_mouse_mode() and not using_controller_mouse):
  Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
 else:
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

 input_mode_changed.emit()


func is_mouse_visible() -> bool:
 return Input.mouse_mode == Input.MOUSE_MODE_VISIBLE


func get_mouse_position(real_only: = false) -> Vector2:
 if real_only or not virtual_cursor.visible:
  return mouse_position

 return virtual_cursor.get_position_without_offset()


func try_drag_tile() -> void :
 var tile: = Tile.get_focused_tile()
 if tile == null:
  return

 if tile.tile_collision.is_pressed and tile.can_drag() and not tile.is_dragging():
  tile.drag_handler.start_drag()


func set_tile_mouse_focus(mouse_focus: = true) -> void :
 var tile: = Tile.get_focused_tile()
 if tile == null:
  return

 if mouse_focus and tile.tile_collision.has_focus(true):
  tile.tile_collision.grab_focus(true)
 elif not mouse_focus and not tile.tile_collision.has_focus(true):
  tile.tile_collision.grab_focus()


func has_non_mouse_focus() -> bool:
 var focus_owner: Control = get_viewport().gui_get_focus_owner()
 if focus_owner == null:
  return false

 return focus_owner.has_focus(true)


func update_right_stick() -> void :
 var right_stick_vector: = get_right_stick_vector()
 if right_stick_vector.is_zero_approx():
  right_stick_recently_touched = false
 else:
  var should_do_mouse: = true
  var minigame: Minigame
  if Game.is_in_run():
   minigame = Game.main.get_active_minigame()

  if minigame != null and minigame.handles_right_stick():
   should_do_mouse = false
  elif left_stick_recently_touched and Game.player.is_using_modifier_spell(true) and Tile.get_focused_tile() != null:
   should_do_mouse = false

  if should_do_mouse:
   using_controller_mouse = true
   update_mouse_visibility()
   set_tile_mouse_focus()
   try_drag_tile()

   var viewport_rect: = get_viewport().get_visible_rect()
   var target_pos: Vector2 = get_mouse_position() + right_stick_vector * CONTROLLER_MOUSE_SPEED
   target_pos = target_pos.clamp(viewport_rect.position, viewport_rect.position + viewport_rect.size - Vector2(1, 1))

   var focus_owner: Control = get_viewport().gui_get_focus_owner()
   if focus_owner != null and focus_owner.has_focus() and can_take_focus():
    if focus_owner.has_focus(true):
     focus_owner.release_focus()
    else:
     var global_rect: = focus_owner.get_global_rect()
     if not global_rect.has_point(focus_owner.get_global_mouse_position()) and not global_rect.has_point(target_pos):
      focus_owner.release_focus()

   warp_mouse(target_pos)


func can_do_left_stick_picking() -> bool:
 if not Game.is_in_run():
  return false

 var minigame: Minigame = Game.main.get_active_minigame()
 if (
  (right_stick_recently_touched and not Game.player.is_using_modifier_spell(true))
  or Game.main.is_paused()
  or using_menu_actions
  or (minigame != null and not minigame.has_left_stick_targeting())
 ):
  return false

 return true


func update_left_stick() -> void :
 if not can_do_left_stick_picking():
  left_stick_focused_node = null
  left_stick_recently_touched = false
 elif (
  Input.is_action_pressed("select_word")
  or not Tile.tile_has_forced_focus()
 ):
  handle_left_stick_picking()


func handle_left_stick_picking() -> void :
 var minigame: Minigame = Game.main.get_active_minigame()
 var left_stick_vector: = get_left_stick_vector()
 if left_stick_vector.is_zero_approx() and (minigame != null or not Input.is_action_pressed("select_word")):
  if left_stick_focused_node != null and left_stick_focused_node.has_focus() and not Tile.any_tile_dragging():
   left_stick_focused_node = null

   var default_focus: Control = Game.tile_board.center_focus_holder
   if minigame != null:
    default_focus = minigame.get_left_stick_focus_holder()

   default_focus.grab_focus()

  left_stick_recently_touched = false
  return

 if minigame != null:
  var targets: = minigame.get_left_stick_targets()
  var target: Control = pick_stick_target(left_stick_vector, minigame.get_left_stick_center(), targets)
  left_stick_focus(target)
 elif Input.is_action_pressed("select_word"):
  var center_position: Vector2 = Game.word_builder.position + Vector2(0, 40)

  var focused_tile: = Tile.get_focused_tile()
  var target: = get_target_tile_collision(Game.word_builder.tiles, center_position, left_stick_vector)
  if target != null and focused_tile != null and target != focused_tile.tile_collision:
   set_tile_mouse_focus(false)
   try_drag_tile()

  if Tile.any_tile_dragging():
   var targets: Dictionary[int, Vector2] = Game.word_builder.word_holder.get_insertion_target_positions(focused_tile)
   var target_index: int = pick_stick_target(left_stick_vector, center_position, targets)
   focused_tile.drag_handler.current_position = targets[target_index]
   focused_tile.drag_handler.update_drag()
  elif target != null:
   snap_to_tile_collision(target)
 else:
  var tiles: Array[Tile] = []
  tiles.assign(Game.tile_board.get_tiles({sorted = true, in_word = false}))
  snap_to_tile(tiles, Game.tile_board.global_position, left_stick_vector, true, Input.is_action_pressed("select_inner_tiles"))


func left_stick_focus(node: Control) -> void :
 left_stick_focused_node = node
 node.grab_focus()


func get_target_tile_collision(tiles: Array[Tile], center_position: Vector2, left_stick_vector: Vector2, force_full_edge_tiles: bool = false, inner_tiles_only: bool = false) -> TileCollision:
 var targets: Dictionary[TileCollision, Vector2] = {}
 var edge_positions: Array[Vector2] = []
 for tile in tiles:
  var is_edge_tile: = tile.is_edge_tile()
  if inner_tiles_only and is_edge_tile:
   continue

  if tile.tile_collision.can_grab_focus():
   targets[tile.tile_collision] = tile.global_position
   if force_full_edge_tiles and is_edge_tile:
    edge_positions.append(tile.global_position)

 if targets.is_empty():
  return null

 return pick_stick_target(left_stick_vector, center_position, targets, edge_positions)


func snap_to_tile_collision(tile_collision: TileCollision) -> void :
 left_stick_focus(tile_collision)

 if Game.player.is_using_modifier_spell(true):
  var spell: TileModifierSpell = Game.player.get_using_spell()
  var region_targets: = spell.get_region_target_positions()
  var target_region = pick_stick_target(get_right_stick_vector(), Vector2(0.01, 0.01), region_targets)
  tile_collision.selected_position = region_targets[target_region] + tile_collision.size / 2


func snap_to_tile(tiles: Array[Tile], center_position: Vector2, left_stick_vector: Vector2, force_full_edge_tiles: bool = false, inner_tiles_only: bool = false) -> bool:
 var target: = get_target_tile_collision(tiles, center_position, left_stick_vector, force_full_edge_tiles, inner_tiles_only)
 if target == null:
  return false

 snap_to_tile_collision(target)
 return true


func pick_stick_target(stick_vector: Vector2, center_position: Vector2, targets: Dictionary, edge_targets: Array[Vector2] = []) -> Variant:
 var compare_distances: Array[float] = []
 for target in targets:
  compare_distances.append(targets[target].distance_to(center_position))

 var stick_strength: float = stick_vector.length()
 var furthest_distance: float = compare_distances.max()
 var closest_to_stick: Variant
 var closest_stick_distance: float = 999999
 for target in targets:
  var pos: Vector2 = targets[target]
  if pos in edge_targets and stick_strength < 0.85:
   continue

  var normal = (pos - center_position) / furthest_distance
  var stick_distance = stick_vector.distance_squared_to(normal)
  if stick_distance < closest_stick_distance:
   closest_to_stick = target
   closest_stick_distance = stick_distance

 return closest_to_stick


func can_do_tile_removing() -> bool:
 return (
  Game.is_in_run()
  and not Game.word_builder.tiles.is_empty()
  and Game.main.is_game_actionable()
  and not Tile.any_tile_dragging()
 )


func update_tile_removing(delta: float) -> void :
 if not can_do_tile_removing() or not Input.is_action_pressed("remove_tile"):
  removing_tiles = false
  remove_tile_cooldown = 0.4
  return

 remove_tile_cooldown -= delta
 if remove_tile_cooldown <= 0.0:
  remove_tile_cooldown += 0.08
  remove_last_or_selected_tile()


func remove_last_or_selected_tile() -> bool:
 var word_builder = Game.word_builder
 var selected_tile: Tile = Tile.get_focused_tile()
 if Tile.is_tile_valid(selected_tile) and selected_tile.in_word():
  word_builder.remove_tile(selected_tile, true, false)
  return true
 elif word_builder.tiles[-1].is_idle():
  word_builder.remove_tile(word_builder.tiles[-1], true, false)
  return true

 return false


func focus_spell(spell_index: int) -> void :
 var minigame: Minigame = Game.main.get_active_minigame()
 if minigame != null and not minigame.spell_picking_enabled():
  return

 var spells: Array[PlayerSpell] = Game.player.spell_container.player_spells
 if spell_index < spells.size():
  var spell: = spells[spell_index]
  if spell.spell_paper.button.has_focus(true) and not spell.spell_paper.button.disabled:
   spell.spell_paper.button.pressed.emit()
  else:
   spell.spell_paper.button.grab_focus()


func warp_mouse(pos: Vector2) -> void :
 release_non_mouse_focus()
 just_warped = true
 get_viewport().warp_mouse(pos)
 mouse_position = pos
 mouse_position_changed.emit()

 var hovered_control: = get_viewport().gui_get_hovered_control()
 if hovered_control != null and hovered_control is Button and Util.can_grab_focus(hovered_control) and not hovered_control.has_focus():
  hovered_control.grab_focus(true)

 set_process(true)


func update_cursor_size() -> void :
 var image_base_size: = Vector2i(16, 16)
 var viewport_scale: = get_viewport().get_stretch_transform().get_scale()
 var viewport_scale_int: = Vector2i(maxi(roundi(viewport_scale.x), 1), maxi(roundi(viewport_scale.y), 1))

 var cursor_scale_setting: = SaveManager.get_cursor_scale()
 if cursor_scale_setting != 0:
  viewport_scale_int = Vector2i(cursor_scale_setting, cursor_scale_setting)

 var mouse_size: = image_base_size * viewport_scale_int
 if mouse_size != cursor_size:
  cursor_size = mouse_size
  for i in cursor_images.size():
   var image: = cursor_images[i]
   image.resize(mouse_size.x, mouse_size.y, Image.INTERPOLATE_NEAREST)

  cursor_hotspot = Vector2i(3, 2) * viewport_scale_int
  update_cursor_image()


func update_cursor_image() -> void :
 if mouse_pressed:
  Input.set_custom_mouse_cursor(cursor_images[1], Input.CURSOR_ARROW, cursor_hotspot)
 else:
  Input.set_custom_mouse_cursor(cursor_images[0], Input.CURSOR_ARROW, cursor_hotspot)


func should_regrab_focus(event: InputEvent) -> bool:
 if event.is_action("primary_button"):
  return false

 var focus_owner: = get_viewport().gui_get_focus_owner()
 if (focus_owner == null or focus_owner is FocusHolder or not focus_owner.has_focus(true)) and event_is_composite_action_pressed(event, &"any_focus"):
  return true
 elif event_is_composite_action_pressed(event, &"any_change_focus"):
  return focus_owner == null or focus_owner.is_in_group("weak_focus")

 return false


func grab_initial_focus() -> void :
 var cutscenes: = get_tree().get_nodes_in_group("cutscene")
 if not cutscenes.is_empty():
  for cutscene_player: CutscenePlayer in cutscenes:
   if cutscene_player.cutscene or cutscene_player.visible:
    cutscene_player.grab_focus()
    return

 var menu_controllers: = get_tree().get_nodes_in_group("menu_controller")
 if not menu_controllers.is_empty():
  menu_controllers.reverse()
  for menu_controller: MenuController in menu_controllers:
   if menu_controller.is_active() and menu_controller.active_menu != null and menu_controller.active_menu.active:
    menu_controller.active_menu.grab_focus()
    return

 if Game.is_in_run():
  var minigame: = Game.main.get_active_minigame()
  if minigame != null:
   var minigame_focus: = minigame.get_default_focus()
   if minigame_focus != null:
    minigame_focus.grab_focus()
    return

  var tiles = Game.tile_board.get_tiles({sorted = true, count = 1, in_word = false})
  if tiles.size() > 0 and tiles[0].tile_collision.can_grab_focus():
   tiles[0].tile_collision.grab_focus()


func set_tile_or_blank_neighbors(tile_or_blank: Variant) -> void :
 var focus: Control
 var coord: Vector2i
 if tile_or_blank is Tile:
  focus = tile_or_blank.tile_collision
  coord = tile_or_blank.get_coord()
 elif tile_or_blank is BoardBlankSpaceFocus:
  focus = tile_or_blank
  coord = tile_or_blank.coord

 var previous: Variant = Game.tile_board.get_neighbor_tile_collision_or_blank(
  coord, 
  Vector2i(-1, 0), 
  true, 
  false, 
  Vector2i(0, 1), 
 )
 Util.set_focus_previous(focus, previous)

 var next: Variant = Game.tile_board.get_neighbor_tile_collision_or_blank(
  coord, 
  Vector2i(1, 0), 
  true, 
  false, 
  Vector2i(0, -1), 
 )
 Util.set_focus_next(focus, next)

 for side in Tile.SIDE_TO_VECTOR:
  var neighbor: Variant = Game.tile_board.get_neighbor_tile_collision_or_blank(
   coord, 
   Tile.SIDE_TO_VECTOR[side], 
   true, 
   false, 
  )

  Util.set_focus_neighbor(focus, side, neighbor)


func setup_tile_focus() -> void :
 var word_builder_collisions: Array[Control] = []
 for tile: Tile in Game.word_builder.tiles:
  word_builder_collisions.append(tile.tile_collision)

 Util.disable_focus_for_controls(word_builder_collisions, false, false)
 Util.set_control_focus_sequence(word_builder_collisions)

 for blank in Game.tile_board.get_blank_spaces():
  blank.update_position()
  if blank.has_focus():
   blank.try_grab_tile_focus()

  set_tile_or_blank_neighbors(blank)

 var board_tiles: Array[Tile] = []
 board_tiles.assign(Game.tile_board.get_tiles({sorted = true, in_word = false}))
 for tile in board_tiles:
  set_tile_or_blank_neighbors(tile)


func set_sub_action_enabled(sub_action: StringName, enabled: bool) -> void :
 var was_disabled: bool = disabled_sub_actions.get(sub_action, false)
 disabled_sub_actions[sub_action] = not enabled
 if disabled_sub_actions[sub_action] != was_disabled:
  sub_actions_need_updating = true


func update_actions() -> void :
 var should_use_menu_actions: = false
 if not Game.is_in_run():
  should_use_menu_actions = true
 else:
  should_use_menu_actions = Game.main.is_node_ready() and (Game.main.menu_controller.is_active() or Game.main.game_menu_controller.is_active())

 using_menu_actions = should_use_menu_actions

 for sub_action in MENU_ACTIONS:
  set_sub_action_enabled(sub_action, should_use_menu_actions)

 var should_use_minigame_actions: = false
 if not should_use_menu_actions:
  var minigame: Minigame = Game.main.get_active_minigame()
  if minigame != null and not minigame.spell_picking_enabled():
   should_use_minigame_actions = true

 set_sub_action_enabled(&"ui_accept_minigame", should_use_minigame_actions)

 var alt_gamepad_layout: = SaveManager.get_spell_gamepad_layout() == 1
 for i in 4:
  set_sub_action_enabled("spell_" + str(i) + "_gamepad", not alt_gamepad_layout)
  set_sub_action_enabled("spell_" + str(i) + "_gamepad_alt", alt_gamepad_layout)

 update_sub_actions()


func update_sub_actions() -> void :
 if not sub_actions_need_updating:
  return

 sub_actions_need_updating = false

 for parent_action in SUB_ACTIONS:
  var sub_actions: Array[StringName] = []
  sub_actions.assign(SUB_ACTIONS[parent_action])

  var enabled_events: Array[InputEvent] = []
  var disabled_events: Array[InputEvent] = []
  for sub_action in sub_actions:
   var is_enabled = sub_action not in disabled_sub_actions or not disabled_sub_actions[sub_action]
   for event in InputMap.action_get_events(sub_action):
    if is_enabled:
     enabled_events.append(event)
    else:
     disabled_events.append(event)

  for event in enabled_events:
   if not InputMap.action_has_event(parent_action, event):
    InputMap.action_add_event(parent_action, event)

  for event in disabled_events:
   var is_enabled: = false
   for enabled_event in enabled_events:
    if enabled_event.is_match(event, true):
     is_enabled = true
     break

   if not is_enabled and InputMap.action_has_event(parent_action, event):
    InputMap.action_erase_event(parent_action, event)


func event_is_composite_action_pressed(event: InputEvent, composite_action: StringName) -> bool:
 for sub_action in COMPOSITE_ACTIONS[composite_action]:
  if event.is_action_pressed(sub_action):
   return true

 return false


func can_take_focus() -> bool:
 var focus_owner: = get_viewport().gui_get_focus_owner()
 if focus_owner == null:
  return true

 if focus_owner is LineEdit:
  return false
 elif focus_owner is TileCollision:
  if not focus_owner.can_release_focus():
   return false
 elif focus_owner.is_in_group("strong_focus"):
  return false

 return true


func vibrate(weak_magnitude: float = 0.1, strong_magnitude: float = 0.0, duration: float = 0.1) -> void :
 if active_joypad == -1 or get_input_mode() != InputMode.CONTROLLER or not SaveManager.get_vibration_enabled():
  return

 Input.start_joy_vibration(active_joypad, weak_magnitude, strong_magnitude, duration)


func _game_start() -> void :
 Game.main.game_state_updated.connect(_game_state_updated)


func _game_state_updated() -> void :
 setup_tile_focus()
 update_actions()


func _gui_focus_changed(node: Control) -> void :
 if not node.has_focus(true) or node is LineEdit:
  return

 using_controller_mouse = false

 if get_input_mode() == InputMode.MOUSE:
  set_input_mode(InputMode.KEYBOARD)

 virtual_cursor.set_snapped_control(node)
 node.focus_exited.connect(_gui_focus_lost.bind(node), CONNECT_ONE_SHOT)


func _gui_focus_lost(node: Control) -> void :
 if node == left_stick_focused_node:
  left_stick_focused_node = null

 virtual_cursor.unsnap_to_control(node)


func _window_size_changed() -> void :
 update_cursor_size()
 window_size_changed_cooldown = 0.1
 set_process(true)


class ActionListener:
 signal pressed
 signal released

 var action: StringName


 func _init(string_name: StringName) -> void :
  action = string_name


 func handle_input(event: InputEvent) -> void :
  if event.is_action_pressed(action):
   pressed.emit()
  elif event.is_action_released(action):
   released.emit()
