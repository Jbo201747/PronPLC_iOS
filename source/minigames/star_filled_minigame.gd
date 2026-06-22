class_name StarFilledMinigame extends Minigame


var original_letter: String = ""
var editing_tile: Tile
var preview_tile_a: Tile
var preview_tile_b: Tile
var tiles: Array[BinaryTile] = []
var tile_scene: PackedScene = preload("res://source/minigames/binary_tile.tscn")

var mosaics = {
 "a": ["\n\t\tOXO\n\t\tXXX\n\t\tXOX\n\t\t"\
\
\
\
, "\n\t\tOXX\n\t\tXOX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "b": ["\n\t\tXXO\n\t\tXXX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "c": ["\n\t\tXXX\n\t\tXOO\n\t\tXXX\n\t\t"\
\
\
\
], 
 "d": ["\n\t\tXXO\n\t\tXOX\n\t\tXXO\n\t\t"\
\
\
\
], 
 "e": ["\n\t\tXXX\n\t\tXXO\n\t\tXXX\n\t\t"\
\
\
\
], 
 "f": ["\n\t\tXXX\n\t\tXXO\n\t\tXOO\n\t\t"\
\
\
\
], 
 "g": ["\n\t\tXXO\n\t\tXOX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "h": ["\n\t\tXOX\n\t\tXXX\n\t\tXOX\n\t\t"\
\
\
\
, "\n\t\tXOO\n\t\tXXX\n\t\tXOX\n\t\t"\
\
\
\
], 
 "i": ["\n\t\tXXX\n\t\tOXO\n\t\tXXX\n\t\t"\
\
\
\
, "\n\t\tOXO\n\t\tOXO\n\t\tOXO\n\t\t"\
\
\
\
], 
 "j": ["\n\t\tOOX\n\t\tXOX\n\t\tXXX\n\t\t"\
\
\
\
, "\n\t\tOXX\n\t\tOOX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "k": ["\n\t\tXOX\n\t\tXXO\n\t\tXOX\n\t\t"\
\
\
\
], 
 "l": ["\n\t\tXOO\n\t\tXOO\n\t\tXXX\n\t\t"\
\
\
\
], 
 "m": ["\n\t\tXXX\n\t\tXXX\n\t\tXOX\n\t\t"\
\
\
\
], 
 "n": ["\n\t\tXXX\n\t\tXOX\n\t\tXOX\n\t\t"\
\
\
\
, "\n\t\tXXO\n\t\tXOX\n\t\tXOX\n\t\t"\
\
\
\
], 
 "o": ["\n\t\tXXX\n\t\tXOX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "p": ["\n\t\tXXX\n\t\tXXX\n\t\tXOO\n\t\t"\
\
\
\
], 
 "q": ["\n\t\tXXX\n\t\tXXX\n\t\tOOX\n\t\t"\
\
\
\
], 
 "r": ["\n\t\tXXO\n\t\tXXX\n\t\tXOX\n\t\t"\
\
\
\
, "\n\t\tXXO\n\t\tXXO\n\t\tXOX\n\t\t"\
\
\
\
, "\n\t\tXXX\n\t\tXOX\n\t\tXOO\n\t\t"\
\
\
\
, "\n\t\tXXO\n\t\tXOX\n\t\tXOO\n\t\t"\
\
\
\
], 
 "s": ["\n\t\tOXX\n\t\tOXO\n\t\tXXO\n\t\t"\
\
\
\
], 
 "t": ["\n\t\tXXX\n\t\tOXO\n\t\tOXO\n\t\t"\
\
\
\
, "\n\t\tOXO\n\t\tXXX\n\t\tOXO\n\t\t"\
\
\
\
], 
 "u": ["\n\t\tXOX\n\t\tXOX\n\t\tXXX\n\t\t"\
\
\
\
, "\n\t\tXOX\n\t\tXOX\n\t\tOXX\n\t\t"\
\
\
\
], 
 "v": ["\n\t\tXOX\n\t\tXOX\n\t\tOXO\n\t\t"\
\
\
\
], 
 "w": ["\n\t\tXOX\n\t\tXXX\n\t\tXXX\n\t\t"\
\
\
\
], 
 "x": ["\n\t\tXOX\n\t\tOXO\n\t\tXOX\n\t\t"\
\
\
\
], 
 "y": ["\n\t\tXOX\n\t\tOXO\n\t\tOXO\n\t\t"\
\
\
\
, "\n\t\tXOX\n\t\tXXX\n\t\tOXO\n\t\t"\
\
\
\
, "\n\t\tXOX\n\t\tOXX\n\t\tOOX\n\t\t"\
\
\
\
], 
 "z": ["\n\t\tXXO\n\t\tOXO\n\t\tOXX\n\t\t"\
\
\
\
], 
}

@onready var board: Sprite2D = %Board
@onready var turns_label: Label = %TurnsLabel

@onready var reset_sprite: Sprite2D = %ResetSprite
@onready var reset_button: Button = %ResetButton
@onready var reset_hover_handler: HoverHandler = %ResetHoverHandler

@onready var confirm_sprite: Sprite2D = %ConfirmSprite
@onready var confirm_tooltip = %ConfirmButtonTooltip

@onready var anim_player = %AnimPlayer


func _ready():
 for letter in mosaics:
  var letter_mosaics = mosaics[letter]

  for i in range(letter_mosaics.size()):
   var mosaic = letter_mosaics[i]
   mosaics[letter][i] = mosaic.replace("\n", "").replace("\t", "")

 var tile_buttons: Array[Button] = []
 for i in range(9):
  var tile: BinaryTile = tile_scene.instantiate()
  var x_pos = (i % 3 - 1) * 22
  var y_pos = (i / 3 - 1) * 22
  y_pos -= 3

  board.add_child(tile)
  tiles.append(tile)
  tile_buttons.append(tile.button)

  tile.position = Vector2(x_pos, y_pos)
  tile.state_changed.connect(update_state)

 Util.set_control_grid_focus([tile_buttons.slice(0, 3), tile_buttons.slice(3, 6), tile_buttons.slice(6, 9)], true, false)


func set_tile(tile: Tile) -> void :
 editing_tile = tile
 if tile.type == Tile.TileType.DAMAGE:
  board.frame = 0
 else:
  board.frame = 1

 set_mosaic(tile.face)


func set_mosaic(letter: String):
 original_letter = letter

 var mosaic = mosaics[letter][0]

 for i in range(9):
  var tile = tiles[i]
  var state = mosaic[i]

  if state == "X":
   tile.set_state(true, true)
  elif state == "O":
   tile.set_state(false, true)

 update_state()


func get_current_letter() -> String:
 var mosaic = ""

 for tile in tiles:
  if tile.state == false:
   mosaic += "O"
  elif tile.state == true:
   mosaic += "X"

 for letter in mosaics:
  if mosaic in mosaics[letter]:
   return letter

 return ""


func appear(instant: = false) -> void :
 await Game.tile_board.slide_out(instant)
 await Game.conditional_timeout(0.16, instant)
 await anim_player.play_until_finished("appear", instant)

 preview_tile_a = Game.tile_board.create_preview_tile(editing_tile)
 preview_tile_b = Game.tile_board.create_preview_tile(editing_tile)
 Game.main.spell_banner.set_tiles(preview_tile_a, preview_tile_b)


func disappear(instant: = false) -> void :
 await anim_player.play_until_finished("disappear", instant)
 await Game.conditional_timeout(0.16, instant)
 await Game.tile_board.slide_in(instant)


func cancel() -> void :
 AudioManager.play_sound(Sounds.UI.WORD_SUBMIT)
 finished.emit()


func confirm() -> void :
 AudioManager.play_sound(Sounds.UI.WORD_SUBMIT)
 finished.emit()


func update_state() -> void :
 var moves_remaining: = 4
 for tile in tiles:
  tile.set_disabled(false)
  if tile.state != tile.original_state:
   moves_remaining -= 1

 if moves_remaining == 0:
  for tile in tiles:
   tile.set_disabled(tile.state == tile.original_state)

 turns_label.text = str(moves_remaining) + "/4"

 reset_button.disabled = moves_remaining == 4
 reset_sprite.frame = 1 if reset_button.disabled else 2
 reset_hover_handler.set_disabled(reset_button.disabled)

 var current_letter: = get_current_letter()

 if preview_tile_b != null:
  if current_letter == "":
   preview_tile_b.set_face("?")
  else:
   preview_tile_b.set_face(current_letter)

 var confirmable: bool = (
  moves_remaining != 4
  and current_letter != ""
  and current_letter != original_letter
 )

 confirm_sprite.frame = 4 if confirmable else 3
 confirm_tooltip.context = {confirmable = confirmable}


func handles_right_stick() -> bool:
 return false


func has_left_stick_targeting() -> bool:
 return true


func get_left_stick_center() -> Vector2:
 return global_position


func get_left_stick_focus_holder() -> Control:
 return tiles[4].button


func get_left_stick_targets() -> Dictionary[Control, Vector2]:
 var targets: Dictionary[Control, Vector2]
 for tile in tiles:
  targets[tile.button] = tile.global_position

 return targets


func get_default_focus() -> Control:
 return tiles[0].button


func _on_confirm_button_pressed() -> void :
 confirm()


func _on_reset_button_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 set_mosaic(original_letter)
 update_state()
