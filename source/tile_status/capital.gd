extends Status


func apply(_data):
 if tile.has_status(TileStatus.PERIOD):
  tile.remove_status(TileStatus.PERIOD)


func invalidates_word():
 if not tile.in_word() or tile.has_faceless_status():
  return false

 var index = tile.find_in_word()

 if index == 0:
  return false

 var tiles = Game.word_builder.tiles
 var prev_tile = tiles[index - 1]

 if not prev_tile.is_space():
  return true
