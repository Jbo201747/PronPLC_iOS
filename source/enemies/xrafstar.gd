extends Enemy


var is_prone = false

var swarming_player = false:
 set(value):
  swarming_player = value

  if swarming_player:
   flies_anim_player.play("swarm_player")
  else:
   flies_anim_player.play("swarm_xrafstar")

  flies_anim_player.advance(0)

@onready var flies = $Sprite / Flies
@onready var flies_anim_player = $Sprite / Flies / AnimPlayer


func _init():
 id = Enemies.XRAFSTAR
 next_move = "extrude"

 moves = {
  extrude = {
   poop = {
    0: 8, 
    1: 10, 
    2: 12, 
   }, 
   status = TileStatus.POOP, 
   next = "pollute", 
  }, 
  pollute = {
   poison = {
    0: 6, 
    1: 7, 
    2: 8, 
    3: 9, 
   }, 
   status = TileStatus.POISON, 
   next = "extrude", 
  }, 
  flies = {
   count = {
    0: 1, 
    1: 2, 
    2: 3, 
    3: 4, 
   }, 
  }, 
 }


func post_ready():
 flies.spawn_flies(moves.flies.count)


func display_intent():
 var count
 if next_move == "extrude":
  count = moves.extrude.poop
 elif next_move == "pollute":
  count = moves.pollute.poison

 var context = {status = moves[next_move].status, count = count}
 if "target" in moves[next_move]:
  context.target = moves[next_move].target

 if "intent_name" in moves[next_move]:
  context.name_override = moves[next_move].intent_name

 if "damage" in moves[next_move]:
  add_intent(Intent.ATTACK, {damage = moves[next_move].damage})

 add_intent(Intent.APPLY_STATUS, context)


func animate_flinch(_damage):
 if is_prone:
  anim_player.play_advance("flinch_parasite")
 else:
  anim_player.play_advance("flinch_host")

 await anim_player.animation_finished


func animate_flinch_lethal():
 for fly in flies.flies:
  fly.target_and_die(Vector2(fly.target_position.x, -100), 5)
  flies.flies[fly] = 10

 if is_prone:
  AudioManager.play_sound(Sounds.XRAFSTAR.PARASITE_FLINCH)
  anim_player.play("dying_parasite")
 else:
  AudioManager.play_sound(Sounds.XRAFSTAR.HOST_FLINCH)
  anim_player.play("dying_host")

 await animate_death()


func animate_death() -> void :
 await Game.timeout(2)

 if is_prone:
  anim_player.play("die_parasite")
 else:
  anim_player.play("die_host")

 await anim_player.animation_finished
 sprite.blood_explode()
 sprite.hide()

 await Game.timeout(0.5)


func _play_idle():
 if is_prone:
  anim_player.play("idle_prone")
 else:
  anim_player.play("idle")


func get_target_tiles(amount):
 var params = {
  amount = amount, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
 }

 if "status" in moves[next_move]:
  if moves[next_move].status == TileStatus.POOP:
   params.effect_priority = AMBIVALENT_EFFECT_PRIORITY

 if "target" in moves[next_move]:
  if moves[next_move].target == "top":
   params.row_priority = tile_board.get_row_coords(true)
  else:
   params.row_priority = tile_board.get_row_coords(false)

 return get_tiles(params)


func extrude():
 is_prone = true

 if not swarming_player:
  swarming_player = true

 var target_tiles = get_target_tiles(moves.extrude.poop)

 anim_player.play("extrude")
 await sprite.hit

 for tile in target_tiles:
  tile.add_status(moves.extrude.status)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)

 await pend_animation_stopped("extrude")


func pollute():
 is_prone = false
 var target_tiles = get_target_tiles(moves.pollute.poison)

 anim_player.play("pollute")
 await sprite.hit

 if "damage" in moves.pollute:
  hit_player(moves.pollute.damage)

 for tile in target_tiles:
  tile.add_status(moves.pollute.status)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)

 await pend_animation_stopped("pollute")


func get_save_data():
 var save = super.get_save_data()
 save["is_prone"] = is_prone
 save["swarming_player"] = swarming_player

 return save


func load_save_data(save):
 super.load_save_data(save)

 is_prone = save.is_prone
 swarming_player = save.swarming_player

 if is_prone:
  anim_player.play("idle_prone")


func apply_fish(tile: Tile, fish: Fish) -> void :
 if next_move == "pollute":
  if fish.rng.randf() <= 0.9:
   tile.add_status(TileStatus.POOP)
 elif times_performed_move.pollute > 0:
  if fish.rng.randf() <= 0.4:
   tile.add_status(TileStatus.POISON)
