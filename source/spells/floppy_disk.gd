extends Spell


enum {
 SAVE, 
 LOAD
}

var state = SAVE
var saved_board = null


func _ready() -> void :
 update_state()


func get_tooltip_context():
 return {save = state == SAVE}


func get_hv_frames() -> Vector2i:
 return Vector2i(1, 2)


func get_frame() -> int:
 if state == SAVE:
  return 0
 else:
  return 1


func update_state():
 if saved_board == null:
  state = SAVE
 else:
  state = LOAD

 frame_updated.emit()
 description_updated.emit()


func _use():
 if saved_board == null:
  saved_board = tile_board.get_tile_state_save_data(false)

  await tile_board.slide_out()
  await tile_board.reset_tiles(true)
  tile_board.reset_board()
  await Game.timeout(0.75)
  await tile_board.slide_in()
  await tile_board.fill_board()
 else:
  await tile_board.slide_out()
  tile_board.load_tile_state_save_data(saved_board, true)
  saved_board = null
  await Game.timeout(0.75)
  await tile_board.slide_in()

 update_state()

 _post_use()


func get_save_data():
 var save = super.get_save_data()
 save.board = saved_board
 return save


func load_save_data(save):
 super.load_save_data(save)
 saved_board = save.board
 update_state()
