extends "res://source/enemies/anti_sex_worker.gd"


func _init():
 super._init()
 id = Enemies.SEX_TRAITOR
 inherited_id = Enemies.ANTI_SEX_WORKER

 cramp_animation = "traitor_cramp"
 moves.protest.bleed = {
  0: 3, 
  1: 4, 
  2: 5
 }
 moves.picket.bleed = 0


func display_intent():
 if next_move == "protest":
  add_intent(Intent.BLEED_FULL_WORD, {count = moves.protest.bleed})

 elif next_move == "picket":
  add_intent(Intent.ATTACK, {damage = moves.picket.damage})


func protest():
 anim_player.play("traitor_cramp")

 await sprite.hit

 var target_tiles = get_tiles({
  amount = moves.protest.bleed, 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 for tile in target_tiles:
  if tile == target_tiles[-1]:
   tile.set_face(Letters.get_random_period_letter(rng.move))
   tile.add_status(TileStatus.PERIOD)
  elif tile == target_tiles[0]:
   tile.set_face(Letters.get_random_capital_letter(rng.move))
   tile.add_status(TileStatus.CAPITAL)

  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(Globals.COLORS.COP_BLOOD, tile.get_color(), true, 0.8)
  tile.tile_overlay_anim_player.play("oxidize_bleed")
  await Game.timeout(0.08)

 await pend_animation_stopped("traitor_cramp")
