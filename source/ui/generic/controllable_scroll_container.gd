class_name ControllableScrollContainer extends ScrollContainer

const SCROLL_TICKRATE: float = 1.0 / 20.0
const SCROLL_MIN_VELOCITY: int = 20
const SCROLL_ACCEL: int = 1
const SCROLL_MAX_VELOCITY: int = 50

signal scroll_changed

var scroll_velocity: int = 0
var active_scroll_bar: ScrollBar

var scroll_left_pressed: = false
var scroll_right_pressed: = false
var scroll_up_pressed: = false
var scroll_down_pressed: = false
var scroll_tick: float = 0.0


func _ready() -> void :
 focus_mode = FOCUS_ALL

 if vertical_scroll_mode != SCROLL_MODE_DISABLED:
  active_scroll_bar = get_v_scroll_bar()
 else:
  active_scroll_bar = get_h_scroll_bar()

 get_h_scroll_bar().value_changed.connect(_scroll_changed.bind(true))
 get_v_scroll_bar().value_changed.connect(_scroll_changed)

 focus_entered.connect(_on_focus_entered)
 focus_exited.connect(_on_focus_exited)


func _scroll_changed(_value: float, horizontal: bool = false) -> void :
 if horizontal:
  active_scroll_bar = get_h_scroll_bar()
 else:
  active_scroll_bar = get_v_scroll_bar()

 scroll_changed.emit()


func get_active_directions() -> Array[InputManager.Direction]:
 var directions: Array[InputManager.Direction] = []
 if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
  directions.append_array([InputManager.Direction.LEFT, InputManager.Direction.RIGHT])

 if vertical_scroll_mode != SCROLL_MODE_DISABLED:
  directions.append_array([InputManager.Direction.UP, InputManager.Direction.DOWN])

 return directions


func _ui_pressed(direction: InputManager.Direction) -> void :
 if direction not in get_active_directions():
  return

 scroll_velocity = mini(scroll_velocity + SCROLL_ACCEL, SCROLL_MAX_VELOCITY)

 if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
  if direction == InputManager.Direction.LEFT:
   scroll_horizontal -= (SCROLL_MIN_VELOCITY + scroll_velocity)
  elif direction == InputManager.Direction.RIGHT:
   scroll_horizontal += (SCROLL_MIN_VELOCITY + scroll_velocity)

 if vertical_scroll_mode != SCROLL_MODE_DISABLED:
  if direction == InputManager.Direction.UP:
   scroll_vertical -= (SCROLL_MIN_VELOCITY + scroll_velocity)
  elif direction == InputManager.Direction.DOWN:
   scroll_vertical += (SCROLL_MIN_VELOCITY + scroll_velocity)


func _ui_released(_direction: InputManager.Direction) -> void :
 if not InputManager.any_ui_pressed(get_active_directions()):
  scroll_velocity = 0


func _on_focus_entered() -> void :
 InputManager.ui_pressed.connect(_ui_pressed)
 InputManager.ui_released.connect(_ui_released)


func _on_focus_exited() -> void :
 scroll_velocity = 0
 InputManager.ui_pressed.disconnect(_ui_pressed)
 InputManager.ui_released.disconnect(_ui_released)
