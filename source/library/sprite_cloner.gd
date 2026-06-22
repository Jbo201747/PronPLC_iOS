@tool
class_name SpriteCloner extends Sprite2D

@export var clone_of: Sprite2D
@export var copy_frame: = true
@export var copy_visibility: = true


func _ready() -> void :
 do_copying()


func _process(_delta: float) -> void :
 do_copying()


func _notification(what: int) -> void :
 if what == NOTIFICATION_EDITOR_PRE_SAVE:
  transform = Transform2D.IDENTITY
  offset = Vector2.ZERO

  if copy_frame:
   hframes = 1
   vframes = 1
   frame = 0
   region_enabled = false
   region_rect = Rect2(0, 0, 0, 0)

  if copy_visibility:
   visible = true
 elif what == NOTIFICATION_EDITOR_POST_SAVE:
  do_copying()


func do_copying() -> void :
 if clone_of == null:
  return

 CopyUtil.copy_transform(clone_of, self)

 if copy_frame:
  CopyUtil.copy_sprite_frame(clone_of, self)

 if copy_visibility:
  CopyUtil.copy_visibility(clone_of, self)
