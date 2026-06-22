extends Enemy

const PROP_SCENE = preload("res://source/effects/bammon_prop.tscn")


@onready var tile_marker: Marker2D = $Sprite / TileMarker
@onready var tile_mask: Sprite2D = $Sprite / Sprite / TileMask
@onready var below_board_hand: Sprite2D = $Sprite / Sprite / Hand / BelowBoardHand

var prop_frames: Array[int] = []
var prop_text_frames: Array[int] = []


func _init():
 id = Enemies.BAMMON
 next_move = "treasure"

 moves = {
  treasure = {
   defense_crits = {
    0: 2
   }, 
   damage_crits = {
    0: 3, 
    3: 2, 
   }, 
   shimmering_damage_crits = {
    0: 0, 
    3: 1, 
   }, 
   next = "assault", 
  }, 
  assault = {
   damage = {
    0: 5, 
    1: 6, 
    2: 8, 
   }, 
   next = "treasure", 
  }, 
 }

 set_process(false)


func _process(_delta: float) -> void :
 if get_viewport().get_visible_rect().has_point(global_position):
  AudioManager.play_sound(Sounds.BAMMON.OINK)
  set_process(false)


func display_intent():
 if next_move == "treasure":
  add_intent(Intent.DOUBLESPEAK, {
   defense_crits = moves.treasure.defense_crits, 
   damage_crits = moves.treasure.damage_crits, 
   shimmering_damage_crits = moves.treasure.shimmering_damage_crits, 
   count = moves.treasure.defense_crits + moves.treasure.damage_crits + moves.treasure.shimmering_damage_crits, 
  })

 elif next_move == "assault":
  add_intent(Intent.ATTACK, {damage = moves.assault.damage + times_performed_move.assault, count = 3})


func start_appearing() -> void :
 anim_player.play_advance("four_legs_good")
 set_process(true)


func play_battle_music(from_save: = false, skipping_transition: = false) -> void :
 if from_save or skipping_transition:
  super.play_battle_music(from_save)


func has_custom_battle_transition() -> bool:
 return true


func custom_battle_transition(skipping: bool = false) -> void :
 if skipping:
  main.show_health()
  return

 AudioManager.play_sound(Sounds.BAMMON.OINK)

 var a_pig = StringManager.get_string("enemy/" + id + "/a_pig")
 var enemy_name = StringManager.get_string("enemy/" + id + "/name")
 var player_name = StringManager.get_string("character/" + player.id + "/title")

 main.versus_label.text = StringManager.get_string("misc/versus_label", {character = player_name, enemy = a_pig})
 main.versus_label.visible_characters = 0
 main.versus_label.show()
 await Game.type_text_with_audio(main.versus_label, 0.025)
 await Game.timeout(1)

 anim_player.play("two_legs_better")

 await sprite.hit

 super.play_battle_music()

 await Game.type_text_with_audio(main.versus_label, 0.02, -1, len(a_pig))
 await Game.timeout(0.5)

 var visible_characters_before: int = main.versus_label.visible_characters
 main.versus_label.text = StringManager.get_string("misc/versus_label", {character = player_name, enemy = enemy_name})
 main.versus_label.visible_characters = visible_characters_before

 await Game.type_text_with_audio(main.versus_label, 0.025, 1, len(enemy_name))
 await Game.timeout(1)
 await Game.type_text_with_audio(main.versus_label, 0.02, -1)

 main.versus_label.hide()
 main.show_health()


func treasure():
 var apply_shimmering_damage_crit_to = []
 if moves.treasure.shimmering_damage_crits > 0:
  apply_shimmering_damage_crit_to = get_tiles({
   amount = moves.treasure.shimmering_damage_crits, 
   type_priority = TileType.DAMAGE, 
   include_effects = [TileStatus.DEFAULT, TileStatus.CRIT], 
   must_include_effects = [TileEffect.SHIMMERING], 
  })

 var apply_defense_crit_to = get_tiles({
  amount = moves.treasure.defense_crits, 
  type_priority = TileType.DEFENSE, 
  include_effects = [TileStatus.DEFAULT, TileStatus.CRIT], 
  must_include_effects = [TileEffect.SHIMMERING], 
  exclude_tiles = apply_shimmering_damage_crit_to, 
 })

 if apply_defense_crit_to.size() < moves.treasure.defense_crits:
  apply_defense_crit_to.append_array(get_tiles({
   amount = moves.treasure.defense_crits - apply_defense_crit_to.size(), 
   type_priority = TileType.DAMAGE, 
   effect_priority = DEFAULT_EFFECT_PRIORITY, 
   exclude_tiles = apply_defense_crit_to + apply_shimmering_damage_crit_to, 
  }))

 if apply_shimmering_damage_crit_to.size() < moves.treasure.shimmering_damage_crits:
  apply_shimmering_damage_crit_to.append_array(
   get_tiles({
    amount = moves.treasure.shimmering_damage_crits - apply_shimmering_damage_crit_to.size(), 
    type_priority = TileType.DAMAGE, 
    effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
    exclude_tiles = apply_defense_crit_to + apply_shimmering_damage_crit_to, 
   })
  )

 var apply_damage_crit_to = get_tiles({
  amount = moves.treasure.damage_crits, 
  effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
  type_priority = TileType.DAMAGE, 
  exclude_tiles = apply_defense_crit_to + apply_shimmering_damage_crit_to, 
 })

 anim_player.play("uncork")

 await sprite.hit

 tile_mask.visible = true

 var tiles_to_throw: Array[Tile] = []
 var tile_to_coord: Dictionary[Tile, Vector2i]

 for tile in apply_damage_crit_to + apply_shimmering_damage_crit_to:
  var new_tile: = tile_board.create_tile()
  main.add_child(new_tile)
  new_tile.copy_tile(tile)
  if tile in apply_shimmering_damage_crit_to:
   new_tile.apply_shimmering(null, null, rng.move)
  new_tile.set_type(TileType.DAMAGE)
  new_tile.add_status(TileStatus.CRIT)
  tiles_to_throw.append(new_tile)
  tile_to_coord[new_tile] = tile.get_coord()

 for tile in apply_defense_crit_to:
  var new_tile: = tile_board.create_tile()
  main.add_child(new_tile)
  new_tile.apply_shimmering(null, null, rng.move)
  new_tile.set_type(TileType.DEFENSE)
  new_tile.add_status(TileStatus.CRIT)
  tiles_to_throw.append(new_tile)
  tile_to_coord[new_tile] = tile.get_coord()

 for tile in tiles_to_throw:
  tile.visible = false

 rng.move.shuffle(tiles_to_throw)

 num_projectiles = tiles_to_throw.size()
 play_crit_launch_sounds(num_projectiles)
 for tile in tiles_to_throw:
  var coord: = tile_to_coord[tile]
  var projectile: = tile.launch(
   tile_marker.global_position, tile_board.get_coord_position(coord), 
   randf_range(64, 96), coord, 800, 
   false, true, false, 
   func(poof_tile: Tile):
    poof_tile.poof_smoke()
  )
  projectile.reparent(sprite)
  tile.z_as_relative = true
  projectile.z_index = -1199
  var tween: = projectile.create_tween()
  tween.tween_interval(0.2)
  tween.tween_callback( func():
   projectile.reparent(main.projectile_container)
   tile.z_as_relative = false
   projectile.z_index = 110
  )
  tile.visible = true
  tile.impacted.connect(_on_projectile_impacted)
  await Game.timeout(randf_range(0.12, 0.16))

 await pend_animation_stopped("uncork")

 if num_projectiles > 0:
  await all_projectiles_impacted

 tile_mask.visible = false

 anim_player.play("uncork_end")
 await pend_animation_stopped("uncork_end")


func play_crit_launch_sounds(num_crits: int) -> void :
 AudioManager.play_sound(Sounds.BAMMON.LAUNCH_CRIT_START)
 if num_crits > 1:
  await Game.timeout(0.08)
  for i in num_crits:
   AudioManager.play_sound(Sounds.BAMMON.LAUNCH_CRIT)
   if i != num_crits - 1:
    await Game.timeout(0.08)


func assault():
 anim_player.play("pull")

 prop_frames = [0, 1, 2, 3, 4]
 rng.move.shuffle(prop_frames)
 prop_text_frames = []
 for i in 3:
  prop_text_frames.append(rng.move.randi_range(0, 2))

 player.use_anvil_flinch = true

 for i in 3:
  await sprite.hit
  AudioManager.play_sound(Sounds.BAMMON.ANVIL, 1.0 - i * 0.05)

  if i == 2:
   player.finishing_anvil_flinch = true

  hit_player(moves.assault.damage + times_performed_move.assault, i == 2)

 player.use_anvil_flinch = false
 player.finishing_anvil_flinch = false

 await anim_player.pend_animation_stopped("pull")
 await anim_player.play_until_finished("pull_end")


func _on_word_submitted(_words: WordList, damage: int, _ending_turn: bool) -> void :
 if will_damage_kill(damage):
  tile_board.doomed_columns = tile_board.get_column_coords()


func animate_flinch_lethal():
 var anim: String = "die"
 if tile_board.num_rows < 4:
  anim = "die_receiver"
 elif tile_board.preview_rows == 0:
  anim = "die_addict"

 anim_player.play(anim)

 below_board_hand.reparent(main.enemy_marker)
 show_above_board()

 tile_board.prepare_to_animate()
 tile_board.anim_player.play("flip_out")
 tile_board.is_slid_out = true
 tile_board.stay_off_screen = true
 tile_board.prevent_filling = true

 await sprite.hit

 word_builder.intent_container.clear_intents()

 var tiles = get_tiles()

 tile_board.remove_tiles(tiles, {
  ignore_status = true, 
  delete_tiles = false, 
  settle = false, 
  restock = false, 
 })

 for tile: Tile in tiles:
  num_projectiles += 1

  var dest = Vector2(tile.global_position.x + randf_range(60, 128), 300)

  var projectile: = tile.launch(
   tile.global_position, dest, 
   randf_range(80, 100), Vector2i.MIN, randf_range(1000, 1200), 
   true, false, false, 
  )
  projectile.look_at_direction = false
  projectile.angular_velocity = PI * 10
  projectile.angular_deceleration = PI * 18
  projectile.decelerate_to = PI * 2

  await Game.timeout(randf_range(0.01, 0.02))

 await tile_board.anim_player.animation_finished

 tile_board.doomed_columns.clear()

 await tile_board.settle_board(true)

 await anim_player.pend_animation_stopped(anim)

 below_board_hand.reparent($Sprite / Sprite / Hand)
 return_below_board()

 sprite.hide()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() < (1.0 / 7.5):
  if fish.rng.randi_range(1, 4) == 1:
   tile.set_type(TileType.DAMAGE)
  else:
   tile.set_type(TileType.DEFENSE)

  tile.add_status(TileStatus.CRIT)
  tile.apply_shimmering(null, null, fish.rng)


func _on_sprite_event(event: String) -> void :
 if event == "spawn_prop":
  var prop_frame: Variant = prop_frames.pop_front()
  var prop_text_frame: Variant = prop_text_frames.pop_front()
  if prop_frame == null:
   prop_frame = 0
   push_warning("Bammon null prop frame!")

  if prop_text_frame == null:
   prop_text_frame = 0
   push_warning("Bammon null prop text frame!")

  var prop: Node2D = PROP_SCENE.instantiate()
  add_child(prop)
  prop.z_index += 20
  prop.set_frame(prop_frame, prop_text_frame)
  prop.global_position = player.sprite.anvil_marker.global_position
  prop.hit.connect(sprite.hit.emit)

 super._on_sprite_event(event)
