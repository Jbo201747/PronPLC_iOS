@tool
class_name TabController extends Control


signal pre_tab_changed(new_tab: TabButton)
signal tab_changed(new_tab: TabButton)

const TAB_BUTTON_SCENE = preload("res://source/ui/menu/generic/tab_button.tscn")

@export var tab_definitions: Array[TabInfo] = []:
 set(value):
  tab_definitions = value
  if is_node_ready():
   update()
@export var menu_panel: MenuPanel

var tab_selected_controls: Dictionary[TabButton, Control] = {}
var tabs: Array[TabButton] = []
var active_tab: TabButton
var tab_group: = ButtonGroup.new()


func _ready() -> void :
 tab_group = ButtonGroup.new()
 tab_group.pressed.connect(_on_tab_button_pressed)
 update()


func _unhandled_input(event: InputEvent) -> void :
 if menu_panel != null and not menu_panel.active:
  return

 var tab_switch_direction: int = 0
 if Input.is_action_just_pressed_by_event("menu_tab_left", event):
  tab_switch_direction = -1
 elif Input.is_action_just_pressed_by_event("menu_tab_right", event):
  tab_switch_direction = 1

 if tab_switch_direction != 0:
  var selected_tab: int = 0
  if active_tab != null:
   selected_tab = tabs.find(active_tab)

  var next_tab: TabButton = tabs[(selected_tab + tab_switch_direction) % tabs.size()]
  set_active_tab(next_tab, true, true)

  accept_event()


func update() -> void :
 var active_tab_key: String
 if active_tab != null:
  active_tab_key = active_tab.string_key

 tabs.clear()

 var children: = get_children()
 var separation: int = 57
 var pos_x: int = 0
 for tab_info in tab_definitions:
  var tab_button: TabButton = children.pop_front()
  if tab_button == null:
   tab_button = TAB_BUTTON_SCENE.instantiate()
   add_child(tab_button)

  tab_button.button_group = tab_group
  tab_button.string_key = tab_info.string_key
  tab_button.tab_control = get_node_or_null(tab_info.tab_control)
  tab_button.position = Vector2(pos_x, 0)

  if tab_definitions.size() > 1:
   if tab_info == tab_definitions[0]:
    tab_button.glyph_state = TabButton.GlyphState.LEFT
   elif tab_info == tab_definitions[-1]:
    tab_button.glyph_state = TabButton.GlyphState.RIGHT
   else:
    tab_button.glyph_state = TabButton.GlyphState.NONE
  else:
   tab_button.glyph_state = TabButton.GlyphState.NONE

  var is_active_tab: bool = tab_button.string_key == active_tab_key
  if Engine.is_editor_hint():
   is_active_tab = tab_info == tab_definitions[0]

  tab_button.button.set_pressed_no_signal(is_active_tab)
  tab_button.selected = is_active_tab
  tabs.append(tab_button)

  pos_x += separation

 for child in children:
  remove_child(child)
  child.queue_free()


func set_active_tab(tab_button: TabButton, play_effects: bool, force_focus: bool = false) -> void :
 if play_effects:
  Game.menu_shake(true)
  AudioManager.play_sound(Sounds.UI.MENU_BUTTON)

 pre_tab_changed.emit(tab_button)

 var had_focus: = false
 if menu_panel != null and menu_panel.active:
  if active_tab != null and menu_panel.last_focus_target_control != null:
   tab_selected_controls[active_tab] = menu_panel.last_focus_target_control

  had_focus = force_focus or Util.has_focus(menu_panel, true)

 active_tab = tab_button
 for tab in tabs:
  tab.selected = tab == active_tab
  tab.tab_control.visible = tab == active_tab

 if menu_panel != null and menu_panel.active:
  menu_panel.setup_internal_focus()

 if had_focus:
  if active_tab in tab_selected_controls:
   tab_selected_controls[active_tab].grab_focus()
  else:
   menu_panel.grab_focus()

 tab_changed.emit(tab_button)


func _on_tab_button_pressed(button: Button) -> void :
 set_active_tab(button.get_node_or_null(button.get_meta("tab")), true)
