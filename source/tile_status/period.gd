extends Status


func apply(_data):
 if tile.has_status(TileStatus.CAPITAL):
  tile.remove_status(TileStatus.CAPITAL)


func invalidates_word():
 if not tile.in_word() or tile.has_faceless_status():
  return false

 var tiles = Game.word_builder.tiles
 var index = tile.find_in_word()
 var last_index = tiles.size() - 1

 if index == last_index:
  return false

 if index < last_index:
  var next_tile: Tile = tiles[index + 1]

  if not next_tile.is_space():
   return true
