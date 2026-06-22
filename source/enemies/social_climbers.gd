extends "res://source/enemies/paddlers.gd"


const SUITS = ["♥", "♠", "♦", "♣"]


func _init():
 id = Enemies.SOCIAL_CLIMBERS
 inherited_id = Enemies.PADDLERS
 next_move = "handoff"

 moves = {
  handoff = {
   custom_call = "wobble", 
   damage = {
    0: 1, 
    3: 2, 
   }, 
   next = "wobble", 
  }, 
  wobble = {
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   next = "handoff", 
  }, 
 }


func display_intent():
 add_intent(Intent.ATTACK, {damage = moves[next_move].damage, count = 2})
 add_intent(Intent.SUIT_PADDLE)


func wobble():
 var num_turns = times_performed_move.wobble + times_performed_move.handoff
 var suits = ["♥", "♣"] if num_turns % 2 == 0 else ["♦", "♠"]

 var suit_tiles = get_tiles({
  amount = 4, 
  include_effects = [TileEffect.SUIT], 
 })

 var target_tiles = get_tiles({
  amount = 4 - suit_tiles.size(), 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
  exclude_effects = [TileEffect.SUIT], 
 })

 target_tiles += suit_tiles

 if yuri_front:
  anim_player.play("yuri_yaoi")
 else:
  anim_player.play("yaoi_yuri")

 for i in 2:
  await sprite.hit
  hit_player(moves[next_move].damage, i == 1)
  apply_suits(suits, target_tiles, not yuri_front)

  if i == 0:
   yuri_front = not yuri_front

 await anim_player.animation_finished
 _play_idle()


func apply_suits(suits, tiles, is_yuri):
 for i in 2:
  if tiles.is_empty():
   break

  var tile = tiles.pop_front()
  var suit = suits[0] if is_yuri else suits[1]
  var status = TileStatus.BLEED if suit == suits[0] else TileStatus.ASH

  tile.set_face(suit)
  tile.add_status(status)
  tile.add_poofcloud(tile.get_color())

  await Game.timeout(0.08)


func handoff():
 await wobble()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.15:
  if fish.rng.randi_range(1, 2) == 1:
   tile.add_status(TileStatus.BLEED)
   tile.set_face(fish.rng.pick_random(["♥", "♦"]))
  else:
   tile.add_status(TileStatus.ASH)
   tile.set_face(fish.rng.pick_random(["♠", "♣"]))
