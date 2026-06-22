extends "res://source/enemies/prole_service.gd"


var saved_board = null


func _init():
 super._init()
 id = Enemies.RECEIVER
 inherited_id = Enemies.PROLE_SERVICE

 moves.bash.damage = {
  0: 5, 
  1: 6, 
  2: 7, 
  3: 9, 
 }


func display_intent():
 if next_move == "smash":
  add_intent(Intent.KEYPAD)

 elif next_move == "bash":
  super.display_intent()


func _phone_smashed():
 saved_board = tile_board.get_tile_state_save_data(true)
 await tile_board.slide_out()
 await tile_board.reset_tiles(true)
 tile_board.set_size(3, 3, 0, 0, true, 0.0)
 tile_board.queue.clear_outside_columns()
 tile_board.update_previews()

 var num_plastic_tiles: = 3
 var numbers = range(9)
 rng.move.shuffle(numbers)

 var i: = 0
 for number in numbers:
  var tile: Tile = tile_board.create_tile()
  main.add_child(tile)

  tile.add_status(TileStatus.DEFAULT)
  if number == 0:
   tile.set_face("*")
  else:
   tile.set_face(str(number + 1))

  if i < num_plastic_tiles:
   tile.set_type(TileType.DEFENSE)

  var coordinate = Vector2i(number % 3, 2 - (number / 3))
  tile_board.insert_tile(tile, coordinate, false)
  i += 1

 tile_board.add_flag("phone_board")

 await tile_board.slide_in()
 phone_smash_completed = true


func _phone_bashed():
 super._phone_bashed()
 await return_board_if_able()


func return_board_if_able() -> void :
 if saved_board != null and tile_board.has_flag("phone_board"):
  await tile_board.slide_out()
  tile_board.load_tile_state_save_data(saved_board, true)
  saved_board = null
  tile_board.remove_flag("phone_board")
  await tile_board.slide_in()


func animate_flinch_lethal() -> void :
 await super.animate_flinch_lethal()
 await return_board_if_able()


func get_save_data():
 var save = super.get_save_data()
 save.saved_board = saved_board
 return save


func load_save_data(save):
 super.load_save_data(save)
 saved_board = save.saved_board


func apply_any_fish(tile: Tile, fish: Fish) -> void :
 if tile_board.has_flag("phone_board"):
  if fish.rng.randi_range(1, 9) == 1:
   tile.set_face("*")
  else:
   tile.set_face(fish.rng.pick_random(Letters.NUMPAD_CHARACTERS.keys()))
 else:
  super.apply_any_fish(tile, fish)
