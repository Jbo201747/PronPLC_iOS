extends Spell


func _use():
 var restock = false

 for _i in range(charge):
  var bottom_row = tile_board.get_row(0)

  if bottom_row.is_empty():
   await tile_board.fill_board()
   _end_use()
   return

  remove_charge(1, true)

  if charge == 0:
   restock = true

  await tile_board.remove_tiles(bottom_row, {
   interval = 0.08, 
   poof_blend = Globals.COLORS.BLEND_SMOKE, 
   restock = restock, 
   tile_color = true, 
  })

  if not restock:
   await Game.timeout(0.1)

 _post_use()
