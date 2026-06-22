class_name LinkedScrollContainer extends ScrollContainer


@export var other_scroll_container: ScrollContainer


func _ready() -> void :
 horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 if other_scroll_container.horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
  get_h_scroll_bar().share(other_scroll_container.get_h_scroll_bar())

 if other_scroll_container.vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
  get_v_scroll_bar().share(other_scroll_container.get_v_scroll_bar())

 mouse_filter = Control.MOUSE_FILTER_IGNORE
 mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
