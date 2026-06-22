extends Enemy


var lash_anim: = "lash"


func _init():
 id = Enemies.UMAMI
 next_move = "chain"

 moves = {
  chain = {
   linked = {
    0: 2, 
    1: 3, 
    3: 4, 
   }, 
   next = "lash", 
  }, 
  lash = {
   bleed = {
    0: 6, 
    1: 7, 
    2: 8, 
   }, 
   next = "chain", 
  }, 
 }


func _play_idle():
 if next_move == "lash":
  anim_player.play("idle_kneeling")
 else:
  anim_player.play("idle")


func animate_flinch(damage):
 flinch_animation = "flinch"
 if next_move == "lash":
  flinch_animation = "flinch_kneeling"

 await super.animate_flinch(damage)


func display_intent():
 if next_move == "chain":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.LINKED, count = moves.chain.linked * 2})

 elif next_move == "lash":
  if "bleed" in moves.lash:
   add_intent(Intent.APPLY_STATUS, {status = TileStatus.BLEED, count = moves.lash.bleed})

  if "damage" in moves.lash:
   add_intent(Intent.ATTACK, {damage = moves.lash.damage})


func animate_flinch_lethal():
 anim_player.play("die")
 await anim_player.animation_finished
 sprite.blood_explode()
 sprite.hide()


func tile_has_valid_partner(tile, parameters):
 var neighbor = tile.get_board_neighbor(Vector2i(1, 0))
 if neighbor == null:
  return false
 else:
  return tile_board._is_tile_valid(neighbor, parameters, false)


func chain():
 var target_pairs = []
 var linked_ids = [Globals.LinkColor.GRAY, Globals.LinkColor.SILVER, Globals.LinkColor.RUSTY]
 var target_columns = [0, 2, 0, 2]
 var target_rows = tile_board.get_row_coords()

 if rng.move.randi_range(0, 1) == 0:
  target_columns.reverse()

 rng.move.shuffle(target_rows)
 rng.move.shuffle(linked_ids)

 while target_pairs.size() < moves.chain.linked:
  if target_columns.is_empty() or target_rows.is_empty():
   break

  var column = target_columns.pop_front()
  var row = target_rows.pop_front()

  var target_tiles = get_tiles({
   amount = 1, 
   columns = [column], 
   rows = [row], 
   has_face = true, 
   exclude_effects = [TileStatus.LINKED], 
   custom_tile_check = tile_has_valid_partner, 
  })

  if target_tiles.size() > 0:
   target_pairs.append(target_tiles)

 for pair in target_pairs:
  var tile = pair[0]
  var right_tile = tile.get_board_neighbor(Vector2i(1, 0))
  pair.append(right_tile)

 anim_player.play("kneel")
 anim_player.queue("idle_kneeling")
 await sprite.hit

 for pair in target_pairs:
  var color = linked_ids.pop_back()
  for tile in pair:
   AudioManager.play_sound(Sounds.TILE.LINKED)
   tile.add_status(TileStatus.LINKED, color)
   tile.animation.play("shake")

   await Game.timeout(0.08)

  await Game.timeout(0.16)

 await pend_animation_stopped("kneel")


func lash():
 anim_player.play(lash_anim)
 anim_player.queue("idle")
 await sprite.hit

 if "damage" in moves.lash:
  hit_player(moves.lash.damage)

 if "bleed" in moves.lash:
  var bleed_targets = get_tiles({
   amount = moves.lash.bleed, 
   effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
  })

  for tile in bleed_targets:
   tile.add_status(TileStatus.BLEED)
   tile.add_poofcloud(Globals.COLORS.BLOOD)

   await Game.timeout(0.08)

 await pend_animation_stopped(lash_anim)


func apply_any_fish(tile: Tile, fish: Fish) -> void :
 if not tile.has_status(TileStatus.LINKED) and fish.rng.randf() <= 0.2:
  tile.add_status(TileStatus.LINKED, {color = fish.minigame.pick_linked_color()})

 if "bleed" not in moves.lash:
  return

 if tile.has_status(TileStatus.LINKED) and not tile.has_exclusive_status():
  if fish.rng.randi_range(1, 3) == 1:
   tile.add_status(TileStatus.BLEED)


func load_save_data(save):
 super.load_save_data(save)
 _play_idle()
