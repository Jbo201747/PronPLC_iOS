extends Node2D


var tween: Tween
var making_transparent: = false

@onready var anim_player = $AnimPlayer


func _ready() -> void :
 Game.tile_selected.connect(check_transparency)
 Game.tile_deselected.connect(check_transparency)

 if Game.tile_board != null:
  Game.tile_board.tile_box.mouse_entered.connect(check_transparency)
  Game.tile_board.tile_box.mouse_exited.connect(check_transparency)


func clear():
 anim_player.play("disappear")
 await anim_player.animation_finished

 get_parent().remove_child(self)
 queue_free()


func should_be_transparent() -> bool:
 var focused_tile: = Tile.get_focused_tile()
 return focused_tile != null and not focused_tile.in_word()


func check_transparency() -> void :
 var transparent: = should_be_transparent()
 if transparent != making_transparent:
  making_transparent = transparent
  if tween:
   tween.kill()

  tween = create_tween().set_ease(Tween.EASE_IN_OUT)
  tween.tween_interval(0.02)
  if making_transparent:
   tween.tween_property(self, "modulate:a", 0.5, 0.2)
  else:
   tween.tween_property(self, "modulate:a", 1.0, 0.2)
