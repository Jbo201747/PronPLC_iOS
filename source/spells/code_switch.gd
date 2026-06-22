extends Spell


func _use():
 var tile_groups = get_tiles({
  has_face = true, 
  exclude_effects = [TileStatus.MYSTERY], 
  group_by_priority = true, 
  row_priority = tile_board.get_row_coords(true), 
  column_priority = tile_board.get_column_coords()})

 AudioManager.play_sound(Sounds.SPELLS.SWITCH)
 Game.screenshake(2, 0.16)

 for tiles in tile_groups:
  rng.spell.shuffle(tiles)

  for tile in tiles:
   bounce_tiles(tiles)

  await Game.timeout(0.08)

 _post_use()


func bounce_tiles(tiles):
 for tile in tiles:
  tile.randomize_similar_face(rng.spell)
  tile.animation.play("bounce")

  await Game.timeout(0.015)
