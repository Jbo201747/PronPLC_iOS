class_name Counter extends RefCounted

signal finished

var count: int = 0:
 set(value):
  value = maxi(0, value)
  if count != value:
   count = value
   if count == 0:
    finished.emit()


func _init(initial_count: int = 0) -> void :
 count = initial_count


func increment(amount: int = 1) -> void :
 count += amount


func decrement(amount: int = 1) -> void :
 count -= amount


func pend_finished() -> void :
 if count > 0:
  await finished
