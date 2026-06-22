extends Enemy

signal phone_smashed

const NUMBER_REPLACEMENT_PRIORITY = [
 [
  TileStatus.DEFAULT, TileStatus.CAPITAL, TileStatus.PERIOD, 
  TileEffect.BIGRAM, TileEffect.TRIGRAM, TileEffect.NUMBER
 ], 
 [
  TileEffect.WILDCARD, TileEffect.SLASHED, TileEffect.SUIT
 ], 
]

@onready var projectile_marker = $Sprite / PhoneSprite / ProjectileMarker

var phone_smash_completed: = false:
 set(value):
  phone_smash_completed = value
  if value:
   phone_smashed.emit()

func _init():
 id = Enemies.PROLE_SERVICE
 next_move = "smash"

 moves = {
  smash = {
   numbers = 5, 
   next = "bash", 
  }, 
  bash = {
   damage = {
    0: 6, 
    1: 7, 
    2: 8, 
    3: 9, 
   }, 
   next = "smash", 
  }, 
 }


func display_intent():
 if next_move == "smash":
  add_intent(Intent.CONVERT_STATUS, {status = TileEffect.NUMBER, count = moves.smash.numbers})

 elif next_move == "bash":
  add_intent(Intent.ATTACK, {damage = moves.bash.damage})


func smash():
 anim_player.play("raise_phone")
 anim_player.queue("smash_phone")
 anim_player.queue("phone_ring")

 if times_performed_move["smash"] < 1:
  anim_player.queue("phone_ring")

 anim_player.queue("answer_phone")
 anim_player.queue("idle")

 await sprite.hit
 phone_smash_completed = false
 _phone_smashed()

 if not anim_player.get_queue().is_empty():
  await pend_animation_played("idle")

 if not phone_smash_completed:
  await phone_smashed


func _phone_smashed():
 Game.screenshake(6, 0.24)
 await _launch_tiles()
 phone_smash_completed = true


func _launch_tiles():
 var num_plastic_tiles = rng.move.randi_range(2, 3)
 var start = projectile_marker.global_position

 var target_tiles = get_tiles({
  amount = moves.smash.numbers, 
  effect_priority = NUMBER_REPLACEMENT_PRIORITY, 
 })

 num_projectiles = target_tiles.size()

 var i = 0
 for target_tile in target_tiles:
  var tile = tile_board.create_tile()
  var coord = target_tile.get_coord()

  main.add_child(tile)
  tile.set_face(rng.move.pick_random(Letters.NUMPAD_CHARACTERS.keys()))

  if i < num_plastic_tiles:
   tile.set_type(TileType.DEFENSE)
  else:
   tile.set_type(TileType.DAMAGE)

  tile.launch(start, tile_board.get_coord_position(coord), randf_range(48, 80), coord)
  tile.impacted.connect(_on_projectile_impacted)
  tile.impacted.connect( func(): AudioManager.play_sound(Sounds.PROLE_SERVICE.TONE))

  i += 1

 if num_projectiles > 0:
  await all_projectiles_impacted


func bash():
 anim_player.play("raise_phone")
 anim_player.queue("bash")
 anim_player.queue("idle")

 await sprite.hit
 await _phone_bashed()

 await pend_animation_played("idle")


func _phone_bashed():
 hit_player(moves.bash.damage)


func apply_any_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 5) == 1:
  tile.set_face(fish.rng.pick_random(Letters.NUMPAD_CHARACTERS.keys()))
