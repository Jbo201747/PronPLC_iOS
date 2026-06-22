extends Enemy


var cramp_animation: String = "period_cramp"

@onready var tile_marker = $Sprite / TileMarker


func _init():
 id = Enemies.ANTI_SEX_WORKER
 next_move = "protest"

 moves = {
  protest = {
   do_period_pair = {
    0: false, 
    2: true, 
   }, 
   next = "picket", 
  }, 
  picket = {
   bleed = {
    0: 4, 
    1: 5, 
   }, 
   damage = {
    0: 3, 
    2: 4, 
    3: 6, 
   }, 
   next = "protest", 
  }, 
 }


func display_intent():
 if next_move == "protest":
  add_intent(Intent.CONVERT_STATUS, {statuses = [TileStatus.PERIOD, TileStatus.BLEED], count = 1, name_override = "menstruate"})

 elif next_move == "picket":
  add_intent(Intent.ATTACK, {damage = moves.picket.damage})
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.BLEED, count = moves.picket.bleed})


func animate_flinch_lethal():
 anim_player.play("die")
 await anim_player.animation_finished
 sprite.blood_explode()
 sprite.hide()
 await Game.timeout(0.5)


func protest():
 anim_player.play(cramp_animation)

 await sprite.hit

 var target_coords = get_tiles({
  amount = 1, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
  type_priority = TileType.DAMAGE, 
  get_coords = true, 
  empty = null, 
 })

 for coord in target_coords:
  var tile = tile_board.create_tile()
  main.add_child(tile)

  if moves.protest.do_period_pair:
   tile.set_face(Letters.get_random_ending_bigram(rng.move))
  else:
   tile.set_face(Letters.get_random_period_letter(rng.move))

  tile.add_status(TileStatus.BLEED)
  tile.add_status(TileStatus.PERIOD)

  tile.launch(tile_marker.global_position, tile_board.get_coord_position(coord), 80, coord, 750, false, true)

  var poofcloud = Poofcloud.instantiate()
  add_child(poofcloud)
  poofcloud.global_position = tile_marker.global_position
  poofcloud.modulate = Globals.COLORS.BLOOD

  await tile.impacted

 await pend_animation_stopped("period_cramp")


func picket():
 anim_player.play("picket")

 await sprite.hit
 hit_player(moves.picket.damage)

 if moves.picket.bleed > 0:
  var bleed_targets = get_tiles({
   amount = moves.picket.bleed, 
   effect_priority = PURE_EFFECT_PRIORITY, 
  })

  for tile in bleed_targets:
   tile.add_status(TileStatus.BLEED)
   tile.add_poofcloud(tile.get_color())

   await Game.timeout(0.08)

 await pend_animation_stopped("picket")


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 3) == 1:
  tile.add_status(TileStatus.BLEED)
