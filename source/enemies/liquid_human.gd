extends Enemy


func _init():
 id = Enemies.LIQUID_HUMAN
 next_move = "coagulate"

 moves = {
  coagulate = {
   damage = 3, 
   pairs = {
    0: 2, 
    1: 3, 
    2: 4, 
    3: 5, 
   }, 
   next = "ambiance", 
  }, 
  ambiance = {
   next = "coagulate", 
  }, 
 }


func display_intent():
 if next_move == "coagulate":
  add_intent(Intent.ATTACK, {damage = moves.coagulate.damage})
  add_intent(Intent.CONVERT_STATUS, {statuses = [TileStatus.BLEED, TileEffect.BIGRAM], count = moves.coagulate.pairs, name_override = "coagulate"})


func animate_flinch_lethal():
 anim_player.play("flinch_lethal")
 anim_player.queue("dying")

 for _i in range(5):
  await sprite.animation_looped

 anim_player.play("die")
 await anim_player.animation_stopped

 sprite.blood_explode()
 add_node_to_background(sprite.get_node("Cracks"))
 sprite.hide()

 await Game.timeout(0.5)


func coagulate():
 anim_player.play("attack")
 anim_player.queue("idle")

 await sprite.hit
 hit_player(moves.coagulate.damage)
 await apply_bleed()


func ambiance():
 AudioManager.play_sound(Sounds.LIQUID_HUMAN.DO_NOTHING)
 await Game.timeout(0.5)


func apply_bleed():
 var apply_to = get_tiles({
  amount = moves.coagulate.pairs, 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 for tile in apply_to:
  var letter_pair = Letters.get_random_bigram(null, rng.move)
  var pause = randf_range(0.04, 0.08)

  await Game.timeout(pause)
  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(Globals.COLORS.BLOOD)
  tile.set_face(letter_pair)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.175:
  tile.add_status(TileStatus.BLEED)
  tile.set_face(Letters.get_random_bigram(null, fish.rng))
