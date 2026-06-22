class_name HoverLabel extends Label


@export var no_shadow: = false
@export var enabled: = true
@export var hover_source: Node:
 set(value):
  hover_source = value
  connect_hover_source()
@export var disable_on_pause: bool = true

var has_mouse: = false:
 get():
  if hover_source is BattleUnitSprite:
   return hover_source.is_hovered
  else:
   return has_mouse
var forced: = false

@onready var anim_player: AnimPlayer = %AnimPlayer


func _ready() -> void :
 if no_shadow:
  %ShadowCloner.enabled = false

 if disable_on_pause:
  Game.main.game_state_updated.connect(update)

 InputManager.input_mode_changed.connect(update)


func connect_hover_source() -> void :
 if hover_source is Control:
  if not hover_source.mouse_entered.is_connected(_on_mouse_entered):
   hover_source.mouse_entered.connect(_on_mouse_entered)
   hover_source.mouse_exited.connect(_on_mouse_exited)
 elif hover_source is Area2D:
  if not hover_source.mouse_entered.is_connected(_on_mouse_entered):
   hover_source.mouse_entered.connect(_on_mouse_entered)
   hover_source.mouse_exited.connect(_on_mouse_exited)
 elif hover_source is BattleUnitSprite:
  if not hover_source.hovered_on.is_connected(update):
   hover_source.hovered_on.connect(update)
   hover_source.hovered_off.connect(update)


func update(instant: = false) -> void :
 if not enabled or (disable_on_pause and Game.main.is_paused()):
  hover_off(instant)
 elif forced or (has_mouse and InputManager.is_mouse_visible()):
  hover_on(instant)
 else:
  hover_off(instant)


func set_disabled(disabled: = false, instant: = false):
 enabled = not disabled
 update(instant)


func set_forced(_forced: = false, instant: = false) -> void :
 forced = _forced
 update(instant)


func hover_on(instant: = false) -> void :
 anim_player.play_reversible_appear_disappear(true, instant)


func hover_off(instant: = false) -> void :
 anim_player.play_reversible_appear_disappear(false, instant)


func _on_mouse_entered() -> void :
 has_mouse = true
 update()


func _on_mouse_exited() -> void :
 has_mouse = false
 update()
