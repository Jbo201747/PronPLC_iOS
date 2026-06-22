extends Node


@onready var dev_console: Window = %DevConsole

var strings: StringManager.StringGroup


func _ready() -> void :
 strings = StringManager.STRINGS



func _unhandled_key_input(event: InputEvent) -> void :
 if event.is_action_pressed("debug_slow"):
  if Engine.time_scale == 1.0 or Engine.time_scale == 0.0:
   Engine.time_scale = 0.1
  elif Engine.time_scale == 0.1:
   Engine.time_scale = 0.01
  else:
   Engine.time_scale = 1.0
 elif event.is_action_pressed("debug_speed"):
  if Engine.time_scale != 5.0:
   Engine.time_scale = 5.0
  else:
   Engine.time_scale = 1.0
 elif event.is_action_pressed("debug_stop"):
  if Engine.time_scale != 1e-07:
   Engine.time_scale = 1e-07
  else:
   Engine.time_scale = 1.0
 elif event.is_action_pressed("toggle_console"):
  if dev_console.visible:
   dev_console.close()
  else:
   dev_console.show()
 elif event.is_action_pressed("debug_break"):
  EngineDebugger.debug()
 elif event.is_action_pressed("debug_macro"):
  dev_console.run_macro()
