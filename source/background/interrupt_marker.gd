class_name BGInterruptMarker extends Marker2D

signal triggered

@export var play_pattern: String = ""
@export var fire_signal: bool = false
@export var trigger_enemy_spawn: bool = false
@export var enemy_spawn_offset: int = 0
@export var use_deceleration: bool = false


func update(background: GameBG) -> void :
 if use_deceleration:
  var decel_distance = background.get_scroll_decel_distance()
  if global_position.x < background.size + decel_distance:
   interrupt(background)
 elif global_position.x <= background.size + 1:
  interrupt(background)


func interrupt(background: GameBG) -> void :
 if fire_signal:
  triggered.emit()
 elif play_pattern != "":
  background.play_pattern(play_pattern)
 elif trigger_enemy_spawn:
  background.trigger_enemy_spawn(global_position + Vector2(enemy_spawn_offset, 0.0))
 else:
  background.interrupt_scrolling(use_deceleration, global_position.x - background.size)

 queue_free()
