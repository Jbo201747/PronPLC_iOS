class_name Cutscene extends Control

signal finished

var string_group: StringManager.StringGroup

var player: CutscenePlayer
var flags: PackedStringArray

var can_advance: bool = false
var auto_progress_timeout: CancelableTimeout


func play() -> void :
 pass


func advance() -> void :
 pass


func try_advance() -> void :
 if can_advance:
  advance()


func cancel_auto_progress() -> void :
 if auto_progress_timeout and is_instance_valid(auto_progress_timeout) and auto_progress_timeout.timeout.is_connected(advance):
  auto_progress_timeout.timeout.disconnect(advance)

 if auto_progress_timeout and auto_progress_timeout.valid:
  auto_progress_timeout.cancel()


func set_auto_progress(duration: float) -> void :
 auto_progress_timeout = Game.cancelable_timeout(duration)
 auto_progress_timeout.timeout.connect(advance)
