class_name CancelableTimeout extends RefCounted

signal cancel_or_timeout
signal timeout
signal canceled


var valid: = true
var is_canceled: = false


func _init(tree: SceneTree, delay: float) -> void :
 var timer: = tree.create_timer(delay)
 timer.timeout.connect(timeout.emit)
 timer.timeout.connect(cancel_or_timeout.emit)
 cancel_or_timeout.connect( func(): valid = false)


func cancel() -> void :
 is_canceled = true
 canceled.emit()
 cancel_or_timeout.emit()
