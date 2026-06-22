extends Enemy


func _init():
 id = Enemies.RUBBER_ANIMAL
 next_move = "spit"

 moves = {
  spit = {
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   next = "lunge", 
  }, 
  lunge = {
   damage = {
    0: 8, 
    1: 9, 
    2: 10, 
    3: 12, 
   }, 
   parry = {
    0: 8, 
    1: 9, 
    2: 10, 
   }, 
   next = "spit", 
  }, 
 }


func display_intent():
 if next_move == "spit":
  add_intent(Intent.ATTACK, {damage = moves.spit.damage})
  add_intent(Intent.BLEED_WILDCARD, {count = 2})

 elif next_move == "lunge":
  if get_needed_parry() != 0:
   add_intent(Intent.ATTACK, {damage = moves.lunge.damage})
  add_parry_intent()


func _play_idle():
 if "parry" in moves[next_move] and not is_parried:
  anim_player.play("growl_idle")
  return

 anim_player.play("idle")


func animate_flinch(damage):
 flinch_animation = "flinch"
 if "parry" in moves[next_move] and is_parried:
  flinch_animation = "flinch_parry"

 await super.animate_flinch(damage)


func spit():
 anim_player.play("spit")

 await sprite.hit
 hit_player(moves.spit.damage)
 await apply_statuses()

 await pend_animation_stopped("spit")

 await anim_player.play_until_finished("growl_start")
 anim_player.play("growl_idle")


func lunge():
 if is_parried:
  await Game.timeout(0.5)
  anim_player.play("idle")
  return

 anim_player.play("lunge")

 await sprite.hit
 hit_player(moves.lunge.damage)

 await pend_animation_stopped("lunge")


func get_applied_face(_use_rng: RNG = rng.move) -> String:
 return "**"


func apply_statuses():
 var apply_to = get_tiles({
  amount = 2, 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 for tile in apply_to:
  tile.set_face(get_applied_face())
  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(Globals.COLORS.BLOOD)

  await Game.timeout(0.16)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 3) == 1:
  tile.add_status(TileStatus.BLEED)
  if fish.rng.randi_range(1, 3) == 1:
   tile.set_face("*")


func load_save_data(save):
 super.load_save_data(save)
 _play_idle()
