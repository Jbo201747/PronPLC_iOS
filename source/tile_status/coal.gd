extends Status


var turns = 1


func get_tooltip_context():
 return {coal_turns = turns}


func apply(data):
 tile.set_face(" ", false)
 tile.remove_face_statuses()

 if data != null:
  turns = data
 else:
  turns = Game.balance.coal_turns


func update_frame() -> void :
 if turns == 2:
  super.update_frame()
 elif tile.type == TileType.DAMAGE:
  tile.tile_sprite.set_frame(6, Globals.TileStatusFrame[id])
 else:
  var frames = [6, 27, 28]
  tile.tile_sprite.set_frame(frames[tile.tile_sprite.wood_variant], Globals.TileStatusFrame[id])


func invalidates_word():
 if not tile_exists():
  return false

 if not tile.in_word() or tile.is_space():
  return false

 return true


func will_destroy_on_turn_end() -> bool:
 return turns == 1


func destroyed_by_spray() -> bool:
 return not tile.is_space()


func get_save_data():
 return turns


func load_save_data(data):
 turns = data
