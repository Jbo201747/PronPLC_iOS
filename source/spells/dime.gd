extends Spell


var rolling_tile = null
var stopped_rolling = false


func _use():
 rolling_tile = null
 stopped_rolling = false

 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 rolling_tile = tile

 AudioManager.play_sound(Sounds.SPELLS.DICE_ROLL_1)
 roll_tile_face(rolling_tile)

 await get_selection()
 stopped_rolling = true

 _post_use()


func roll_tile_face(tile):
 var interval = 0.02

 for i in range(52):
  if stopped_rolling:
   break

  var new_face: = Letters.shift_face(
   tile.face, 
   [Letters.ALPHABET, Letters.NUMPAD_CHARACTERS.keys()], 
   1
  )
  tile.set_face(new_face)

  await Game.timeout(interval)
  interval = clamp(interval + 0.01, 0.02, 0.25)

 if not stopped_rolling:
  player.selected.emit(null)


func is_tile_selectable(tile):
 if rolling_tile == null:
  return tile.is_single_letter(false, true) and not tile.has_status(TileStatus.MYSTERY)
 else:
  return tile == rolling_tile
