extends Enemy


var ash_letter = "z"
var fish_chance = 0.5


func _init():
 id = Enemies.NOPPY
 next_move = "toss"

 moves = {
  dream = {
   ash = 6, 





  }, 
  toss = {
   damage = {
    0: 1, 
    1: 2, 
    2: 3, 
   }, 
   next = "turn", 
  }, 
  turn = {
   damage = {
    0: 2, 
    1: 3, 
    2: 4, 
    3: 6, 
   }, 
   next = "toss", 
  }, 
 }


func display_intent():
 if next_move == "toss":
  add_intent(Intent.ATTACK, {damage = moves.toss.damage})
  add_intent(Intent.DREAM, {count = moves.dream.ash, letter = ash_letter})

 elif next_move == "turn":
  add_intent(Intent.ATTACK, {damage = moves.turn.damage})
  add_intent(Intent.DREAM, {count = moves.dream.ash, letter = ash_letter})


func dream():
 var num_vowels = get_tiles({
  exclude_letters = Letters.CONSONANTS, 
  has_face = true, 
 }).size()

 var max_targeted_vowels = max(0, num_vowels - 3)

 var outer_column_tiles = get_tiles({
  columns = [0, -1], 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 var outer_row_tiles = get_tiles({
  rows = [0, -1], 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 var outer_tiles = []
 for tile in outer_column_tiles + outer_row_tiles:
  if tile not in outer_tiles:
   outer_tiles.append(tile)

 rng.move.shuffle(outer_tiles)


 var num_targeted_vowels = 0
 for tile in outer_tiles:
  if tile.face not in Letters.VOWELS:
   continue

  num_targeted_vowels += 1
  if num_targeted_vowels > max_targeted_vowels:
   outer_tiles.erase(tile)


 for tile in outer_tiles:
  if tile.type == TileType.DEFENSE:
   outer_tiles.erase(tile)
   outer_tiles.append(tile)
   break


 while outer_tiles.size() > moves.dream.ash:
  outer_tiles.pop_front()

 rng.move.shuffle(outer_tiles)

 var delay = 0.5
 for tile in outer_tiles:
  tile.add_status(TileStatus.ASH)
  tile.add_poofcloud(Globals.COLORS.ASH)
  tile.set_face(ash_letter)




  await Game.timeout(delay)
  delay = max(0.08, delay - 0.1)


func toss():
 await wrap_up_idle()

 anim_player.play("blow_bubble")

 await sprite.hit
 Game.screenshake(6, 0.24)
 hit_player(moves.toss.damage)
 await dream()


func turn():
 await wrap_up_idle()

 anim_player.play("bubble_balloon")

 await sprite.hit
 Game.screenshake(8, 0.24)
 hit_player(moves.turn.damage)
 await dream()


func animate_flinch_lethal():
 anim_player.play("dying")
 await anim_player.animation_finished


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= fish_chance:
  fish.no_variation = true
  tile.add_status(TileStatus.ASH)
  tile.set_face(ash_letter)
