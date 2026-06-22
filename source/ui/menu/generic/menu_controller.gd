class_name MenuController extends Control

signal active
signal inactive
signal done_processing
signal active_menu_changed

signal first_menu_appear_start(menu: MenuPanel)
signal first_menu_appear_finish(menu: MenuPanel)
signal last_menu_disappear_start(menu: MenuPanel)
signal last_menu_disappear_finish(menu: MenuPanel)

signal menu_appear_start(menu: MenuPanel)
signal menu_appear_finish(menu: MenuPanel)
signal menu_disappear_start(menu: MenuPanel)
signal menu_disappear_finish(menu: MenuPanel)

@export var back_button: MainMenuButton
@export var blocks_input: bool = true

var menu_path: Array[MenuPanel] = []
var active_menu: MenuPanel = null:
 set(value):
  active_menu = value
  if blocks_input:
   if active_menu != null:
    mouse_filter = Control.MOUSE_FILTER_PASS
   else:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

  active_menu_changed.emit()

var currently_processing: bool = false:
 set(value):
  currently_processing = value
  if not value:
   done_processing.emit()


func _ready() -> void :
 add_to_group("menu_controller")
 if back_button != null:
  back_button.pressed.connect(_on_back_button_pressed)


func set_menu(menu_node: MenuPanel, instant: = false) -> void :
 currently_processing = true

 var is_first_open: = active_menu == null

 menu_path.append(menu_node)
 await close_menu(false, false, instant)
 await open_menu(menu_node, is_first_open, instant)

 if not InputManager.is_mouse_mode():
  active_menu.grab_focus()

 currently_processing = false


func close_menu(check_back: = true, is_last_closing: = false, instant: = false) -> void :
 if active_menu == null:
  return

 if is_last_closing:
  last_menu_disappear_start.emit(active_menu)

 menu_disappear_start.emit(active_menu)
 active_menu.start_disappear()

 if back_button != null:
  back_button.start_disappear()
  if check_back:
   check_back_button()
 await active_menu.disappear(instant)

 if back_button != null:
  back_button.finish_disappear()

 active_menu.finish_disappear()
 menu_disappear_finish.emit(active_menu)

 if is_last_closing:
  last_menu_disappear_finish.emit(active_menu)

 active_menu.request_back.disconnect(back)
 active_menu.request_close.disconnect(try_full_close)
 active_menu = null


func open_menu(menu_node: MenuPanel, is_first_open: = false, instant: = false) -> void :
 active_menu = menu_node
 active_menu.set_menu_controller(self)
 active_menu.request_back.connect(back)
 active_menu.request_close.connect(try_full_close)

 if is_first_open:
  active.emit()
  first_menu_appear_start.emit(menu_node)

 menu_appear_start.emit(menu_node)
 menu_node.start_appear()

 if back_button != null:
  back_button.start_appear()
  check_back_button()

 await menu_node.appear(instant)

 if back_button != null:
  back_button.finish_appear()

 menu_node.finish_appear()
 menu_appear_finish.emit(menu_node)

 if is_first_open:
  first_menu_appear_finish.emit(menu_node)


func check_back_button() -> void :
 var should_hide_back: = false
 if menu_path.size() == 0:
  should_hide_back = true
 elif not menu_path[-1].can_close:
  should_hide_back = true

 if menu_path.size() != 0 and menu_path[-1].no_back_button:
  should_hide_back = true

 if should_hide_back and back_button.visible:
  await back_button.disappear()
 elif not should_hide_back and not back_button.visible:
  await back_button.appear()


func back() -> void :
 AudioManager.play_sound(Sounds.UI.BACK)
 AudioManager.play_sound(Sounds.UI.BACK_PAPER)

 currently_processing = true
 menu_path.pop_back()

 await close_menu(true, menu_path.is_empty())

 if menu_path.is_empty():
  currently_processing = false
  inactive.emit()
  return

 await open_menu(menu_path[-1])

 if not InputManager.is_mouse_mode():
  active_menu.grab_focus()

 currently_processing = false


func full_close() -> void :
 if currently_processing:
  return

 currently_processing = true
 menu_path.clear()
 await close_menu(true, true)
 currently_processing = false
 inactive.emit()


func try_full_close():
 if currently_processing:
  await done_processing

 if active_menu != null:
  await full_close()


func is_active() -> bool:
 return currently_processing or active_menu != null


func can_press_back() -> bool:
 if currently_processing or not is_active():
  return false

 return menu_path[-1].can_close


func _on_back_button_pressed() -> void :
 if can_press_back():
  back()


func handle_input(event: InputEvent) -> void :
 if event.is_action_pressed("menu_back") and can_press_back():
  var focus_owner: = get_viewport().gui_get_focus_owner()
  if focus_owner is LineEdit:
   focus_owner.release_focus()
  else:
   back()

  accept_event()



func _gui_input(event: InputEvent) -> void :
 handle_input(event)


func _unhandled_input(event: InputEvent) -> void :
 handle_input(event)
