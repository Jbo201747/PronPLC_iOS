class_name IconSelector extends HBoxContainer


signal selected(icon: SelectorIcon)


@export var incremental_selection: = false
@export var selection_sound: SoundRef
@export var max_selection_sound: SoundRef

var animating: = false
var selected_index: int = 0
var icons: Array[SelectorIcon] = []

@onready var container: HBoxContainer = %IconContainer


func _ready() -> void :
 focus_entered.connect(_on_focus_entered)
 focus_exited.connect(_on_focus_exited)


func get_selected_icon() -> SelectorIcon:
 return icons[selected_index]


func set_icons(new_icons: Array[SelectorIcon]) -> void :
 for child in container.get_children():
  child.queue_free()

 var index: = 0
 for icon in new_icons:
  container.add_child(icon)
  icon.pressed.connect(select.bind(index))
  icon.hover_handler.hover_condition = func(): return get_selected_icon() == icon and has_focus(true)
  index += 1

 icons = new_icons


func set_initial_selection(index: int):
 selected_index = index

 for icon_index in icons.size():
  var icon: = icons[icon_index]
  var is_selected: bool = selected_index == icon_index
  if incremental_selection:
   is_selected = selected_index >= icon_index

  icon.init_select_state(is_selected)


func get_next_selectable_index(index: int, direction: int) -> Variant:
 if direction == 0:
  return null

 while true:
  index += direction
  if index < 0 or index >= icons.size():
   return null
  elif icons[index].is_selectable():
   return index

 return null


func select(index: int, direction: int = 0):
 if animating:
  return

 Game.menu_shake(true)

 index = clampi(index, 0, icons.size() - 1)

 if not icons[index].is_selectable():
  if direction == 0:
   icons[index].select_failed()
   return
  elif not incremental_selection:
   var next_selectable_index: Variant = get_next_selectable_index(index, direction)
   if next_selectable_index == null:
    index = selected_index
   else:
    index = next_selectable_index
  else:
   index = selected_index

 var select_sound: SoundRef
 if max_selection_sound != null and get_next_selectable_index(index, 1) == null:
  select_sound = max_selection_sound
 else:
  select_sound = selection_sound

 if selected_index == index:
  AudioManager.play_sound(select_sound)
  icons[index].nudge()
 else:
  selected.emit(icons[index])
  if incremental_selection:
   animating = true
   if index < selected_index:
    for icon_index in range(selected_index, index, -1):
     var icon: = icons[icon_index]
     AudioManager.play_sound(selection_sound)
     icon.deselect()
     if icon_index != index + 1:
      await Game.timeout(0.04)
   else:
    for icon_index in range(selected_index + 1, index + 1):
     var icon: = icons[icon_index]
     icon.select()
     if icon_index != index:
      AudioManager.play_sound(selection_sound)
      await Game.timeout(0.04)
     else:
      AudioManager.play_sound(select_sound)

   animating = false
   selected_index = index
  else:
   AudioManager.play_sound(select_sound)
   icons[selected_index].deselect()
   selected_index = index
   icons[index].select()

 update_icon_hover_state()


func update_icon_hover_state() -> void :
 for icon in icons:
  icon.hover_handler.hover_for_state()


func _on_left_arrow_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 if not animating:
  select(selected_index - 1, -1)


func _on_right_arrow_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 if not animating:
  select(selected_index + 1, 1)


func _on_ui_pressed(direction: InputManager.Direction) -> void :
 if direction == InputManager.Direction.LEFT:
  _on_left_arrow_pressed()
 elif direction == InputManager.Direction.RIGHT:
  _on_right_arrow_pressed()


func _on_focus_entered() -> void :
 update_icon_hover_state()
 if not InputManager.ui_pressed.is_connected(_on_ui_pressed):
  InputManager.ui_pressed.connect(_on_ui_pressed)


func _on_focus_exited() -> void :
 update_icon_hover_state()
 if InputManager.ui_pressed.is_connected(_on_ui_pressed):
  InputManager.ui_pressed.disconnect(_on_ui_pressed)
