extends Spell


func _use():
 var tile: = await get_selection()

 if tile == null:
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)

 if has_curse(CURSE.CURSED) and not tile_board.restock_locked:
  var preview_tile = tile_board.queue.get_preview(tile.get_coord().x, 0)
  if preview_tile != null:
   if "statuses" in preview_tile:
    if TileStatus.CRIT not in preview_tile.statuses:
     preview_tile.can_crit = true
     preview_tile.statuses.append(TileStatus.CURSED)
   else:
    preview_tile.can_crit = true
    preview_tile.statuses = [TileStatus.CURSED]

 tile.add_poofcloud(Globals.COLORS.SMOKE, Globals.COLORS.BLEND_SMOKE)

 tile_board.remove_tile(tile, {
  delete_tiles = false, 
 })

 var bounce_offset: = randf_range(32, 72)
 var direction: = randi_range(0, 1)
 var direction_sign: = -1 if direction == 0 else 1
 var dest = Vector2(tile.global_position.x + bounce_offset * direction_sign, 290)
 var projectile: = tile.launch(tile.global_position, dest, 32, Vector2i.MIN, 1200, true, false, false)
 projectile.look_at_direction = false
 projectile.angular_velocity = PI * 10
 projectile.angular_deceleration = PI * 18
 projectile.decelerate_to = PI * 2

 if main.tutorial.active and "letter_opener" in main.tutorial.current_line_flags:
  main.tutorial.letter_opener_removed = tile.face
  main.tutorial.advance()

 _post_use()


func is_tile_selectable(tile):
 return not tile.has_harmful_status()
