extends Status


func invalidates_word():
 if not tile_exists():
  return

 if not tile.in_word():
  return

 var tiles = Game.word_builder.tiles
 var last_index = tiles.size() - 1
 var index = tiles.find(tile)

 if index > 0:
  var prev_tile = tiles[index - 1]
  if is_comphet(prev_tile):
   return true

 if index < last_index:
  var next_tile = tiles[index + 1]
  if is_comphet(next_tile):
   return true


func is_comphet(other_tile):
 if tile.has_status(TileStatus.GAY) and other_tile.has_status(TileStatus.GAY):
  if tile.type != other_tile.type:
   return true
