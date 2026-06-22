class_name MultiPanelMenu extends MenuPanel


@export var separation: float = 4.0
@export var origin: Vector2 = Vector2(240.0, 270.0)


func animate_appear(instant: bool = false) -> void :
 var positioned_panels: Array[MenuPanel] = []
 var panels: Array[MenuPanel] = []
 var total_panel_size: float = 0.0
 for child in get_children():
  if child is MenuPanel and not child.is_in_group("multipanel_exclude") and not child.forced_hidden:
   if not child.is_in_group("multipanel_position_exclude"):
    total_panel_size += child.get_panel_size().x
    positioned_panels.append(child)
   panels.append(child)

 var total_separation: float = (positioned_panels.size() - 1) * separation
 var separated_panel_size: float = total_panel_size + total_separation

 var panel_x: = floorf(origin.x - separated_panel_size / 2.0)

 for menu_panel: MenuPanel in panels:
  menu_panel.hide()
  if not menu_panel.is_in_group("multipanel_position_exclude"):
   menu_panel.position = Vector2(panel_x, origin.y)
   panel_x += menu_panel.get_panel_size().x + separation

 await sequenced_appear(panels, instant, 0.08, true)


func animate_disappear(instant: bool = false) -> void :
 await sequenced_disappear(get_menu_panel_children(), instant)


func get_focus_controls() -> Array[Control]:
 var sub_panels: Array[Control] = []
 for child in get_children():
  if (
    child is MenuPanel
    and not child.is_in_group("multipanel_exclude")
    and not child.is_in_group("focus_exclude")
    and not child.forced_hidden
    and child.can_grab_focus()
  ):
   sub_panels.append(child)

 return sub_panels
