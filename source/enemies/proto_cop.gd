extends "res://source/enemies/liquid_human.gd"


func _init():
 id = Enemies.PROTO_COP
 inherited_id = Enemies.LIQUID_HUMAN
 next_move = "coagulate"

 moves = {
  coagulate = {
   damage = {
    0: 1, 
    1: 2, 
   }, 
   polycules = {
    0: 2, 
    2: 3, 
    3: 4, 
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
  add_intent(Intent.CONVERT_STATUS, {statuses = [TileStatus.BLEED, TileEffect.TRIGRAM], count = moves.coagulate.polycules, name_override = "coagulate_trigram"})


func apply_bleed():
 var polycule_targets = get_tiles({
  amount = moves.coagulate.polycules, 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 for tile in polycule_targets:
  var letter_polycule = Letters.get_random_trigram(rng.move)
  var pause = randf_range(0.04, 0.08)

  tile.set_face(letter_polycule)
  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(Globals.COLORS.COP_BLOOD, tile.get_color(), true, 0.8)
  tile.tile_overlay_anim_player.play("oxidize_bleed")

  await Game.timeout(pause)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.15:
  tile.add_status(TileStatus.BLEED)
  tile.set_face(Letters.get_random_trigram(fish.rng))
