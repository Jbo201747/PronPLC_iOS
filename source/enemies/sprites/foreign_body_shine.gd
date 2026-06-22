extends Sprite2D


@onready var saw = get_parent().get_child(1)
@onready var shine = $Shine


func _ready() -> void :
 do_copying()


func _process(delta):
 region_rect.position.x -= 30 * delta
 do_copying()


func do_copying() -> void :
 CopyUtil.copy_transform(saw, shine)
 CopyUtil.copy_sprite_frame(saw, shine)
 CopyUtil.copy_visibility(saw, shine)
