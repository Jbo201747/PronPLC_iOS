extends Enemy


var pacifist_turns: int = 0
var knead_status = TileStatus.BLEED
var knead_type_priority = null
var fish_chance: float = 0.2


func _init():
 id = Enemies.FAT_CAT
 next_move = "knead"

 moves = {
  all = {
   can_leave = true, 
  }, 
  knead = {
   bleed = {
    0: 3, 
    2: 4, 
    3: 5, 
   }, 
   next = "knead_b", 
  }, 
  knead_b = {
   custom_call = "knead", 
   next = "lick", 
  }, 
  lick = {
   damage = {
    0: 2, 
    1: 3, 
    3: 4, 
   }, 
   count = 2, 
   next = "knead", 
  }, 
 }


func display_intent():
 if next_move == "knead" or next_move == "knead_b":
  if "bleed" in moves.knead:
   add_intent(Intent.APPLY_STATUS, {status = knead_status, count = moves.knead.bleed})
  else:
   add_intent(Intent.ATTACK, {damage = moves.knead.damage, count = moves.knead.count})

 elif next_move == "lick":
  add_intent(Intent.ATTACK, {damage = moves.lick.damage, count = moves.lick.count})


func animate_flinch_lethal():
 if randi_range(1, 1000) <= 1:
  anim_player.play("dying_rare")
 else:
  anim_player.play("dying")

 await animate_death()


func knead():
 var total_hits: int = 0
 if "bleed" in moves.knead:
  total_hits = moves.knead.bleed
 else:
  total_hits = moves.knead.count

 anim_player.play("knead_start")

 for i in range(total_hits):
  if i % 2 == 0:
   anim_player.queue("knead_a")
  else:
   anim_player.queue("knead_b")

 anim_player.queue("knead_end")
 anim_player.queue("idle")

 var target_tiles = []
 if "bleed" in moves.knead:
  target_tiles = get_tiles({
   amount = total_hits, 
   effect_priority = DEFAULT_EFFECT_PRIORITY, 
   type_priority = knead_type_priority
  })

 for i in total_hits:
  await sprite.hit

  if "damage" in moves.knead:
   hit_player(moves.knead.damage, i == total_hits - 1)

  if target_tiles.is_empty():
   continue

  var tile = target_tiles.pop_front()
  tile.add_status(knead_status)
  tile.add_poofcloud(tile.get_color())
  Game.screenshake(4, 0.32)

 await pend_animation_played("idle")
 await try_to_leave()


func lick():
 anim_player.play("lick")

 for i in range(moves.lick.count):
  await sprite.hit
  hit_player(moves.lick.damage, i == moves.lick.count - 1)

 await anim_player.animation_finished
 await try_to_leave()


func try_to_leave() -> void :
 if not moves.all.can_leave:
  return

 if damage_taken <= 0:
  pacifist_turns += 1
 else:
  pacifist_turns = 0

 if pacifist_turns >= 3:
  anim_player.play("leap")
  await anim_player.animation_finished
  await health_bar.disappear()
  sprite.hide()
  is_defeated = true


func get_save_data():
 var save = super.get_save_data()
 save.pacifist_turns = pacifist_turns
 return save


func load_save_data(save):
 super.load_save_data(save)
 pacifist_turns = save.get("pacifist_turns", 0)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= fish_chance:
  tile.add_status(knead_status)
