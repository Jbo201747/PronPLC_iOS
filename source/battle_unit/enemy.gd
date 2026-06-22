class_name Enemy extends BattleUnit


signal all_projectiles_impacted


const PURE_EFFECT_PRIORITY = Globals.PURE_EFFECT_PRIORITY
const DEFAULT_EFFECT_PRIORITY = Globals.DEFAULT_ENEMY_EFFECT_PRIORITY
const AMBIVALENT_EFFECT_PRIORITY = Globals.AMBIVALENT_ENEMY_EFFECT_PRIORITY

var inherited_id = null
var moves = []
var opening_move = null
var next_move = null
var last_move = null
var next_move_override = null
var times_acted = 0
var times_performed_move = {}
var is_parried = false
var unscaled_moves = null
var launching_from_enemy_scene = false
var triggering_player_turn_end = false
var despawn_on_death: = true
var battle_started: = false
var keep_board_out: = false
var is_playing_cutscene: = false
var num_projectiles: = 0:
 set(value):
  if value == num_projectiles:
   return

  num_projectiles = value
  if value <= 0:
   all_projectiles_impacted.emit()

var player:
 get:
  return Game.player

@onready var tile_board: = Game.tile_board
@onready var word_builder = Game.word_builder


func _ready():
 if get_tree().current_scene == self:
  launching_from_enemy_scene = true
  Game.debug_spawn_enemy = id
  if id != Enemies.NOBODY:
   Game.start_run.call_deferred(Globals.CHARACTERS.LEXICOGRAPHER)
  return

 sprite.unit_is_enemy = true
 super._ready()
 _scale_moves()
 word_builder.submitted_word.connect(_on_word_submitted)
 word_builder.finished_updating_stats.connect(_on_finished_updating_stats)
 Game.difficulty_changed.connect(_difficulty_changed)


func _init_rng():
 rng.move = RNG.new()
 rng.tile = RNG.new()


func _difficulty_changed() -> void :
 _scale_moves()
 pre_start_battle()
 start_battle()


func pre_start_battle() -> void :
 for move in moves:
  times_performed_move[move] = 0

 _scale_health()


func start_battle():
 await prepare_first_turn()

 if opening_move != null:
  await call(opening_move)

 await prepare_next_turn()

 battle_started = true


func has_custom_battle_transition() -> bool:
 return false


func custom_battle_transition(_skipping: bool = false) -> void :
 pass


func play_battle_music(_from_save: = false, _skipping_transition: = false) -> void :
 if id in Enemies.MUSIC:
  AudioManager.play_music(Enemies.MUSIC[id], true)
 elif inherited_id in Enemies.MUSIC:
  AudioManager.play_music(Enemies.MUSIC[inherited_id], true)
 else:
  AudioManager.play_music(Globals.MUSIC.PREFACE, true)


func end_battle_music() -> void :
 AudioManager.stop_music()
 if id in Enemies.BOSSES:
  AudioManager.play_sound(Sounds.STINGERS.BOSS_DEATH)
 else:
  AudioManager.play_sound(Sounds.STINGERS.ENEMY_DEATH)



func post_ready():
 pass



func prepare_first_turn():
 pass


func prepare_next_turn():
 update_intents()

 if "defense" in moves[next_move]:
  defense = moves[next_move].defense


func act():
 var move_call = next_move

 if "custom_call" in moves[next_move]:
  move_call = moves[next_move].custom_call

 await clear_intent()
 await call(move_call)

 times_performed_move[next_move] += 1

 last_move = next_move

 if next_move_override != null:
  next_move = next_move_override
  next_move_override = null
 else:
  next_move = moves[next_move].next

 await tile_board.wait_for_idle_tiles()
 await tile_board.settle_board()
 await tile_board.fill_board()

 emit_signal("action_finished")


func end_turn():
 super.end_turn()

 AchievementManager.enemy_attacked(player.damage_received, 
   player.damage_taken, player.defense)

 is_parried = false
 defense = 0

 if not is_defeated and not player.is_defeated:
  await prepare_next_turn()


func is_player():
 return false


func get_unit_name() -> String:
 return StringManager.get_string("enemy/" + id + "/name")


func get_tiles(parameters = {}):
 parameters.rng = rng.tile
 return tile_board.get_tiles(parameters)


func hit_player(amount: int, attack_finished: = true) -> void :
 deal_damage(player, amount)
 if attack_finished:
  player.recompose()


func _scale_moves():
 var is_debug = Bridge.is_debug_build()
 if unscaled_moves == null and is_debug:
  unscaled_moves = moves.duplicate(true)

 var scaling_moves = moves
 if is_debug:
  scaling_moves = unscaled_moves

 moves = Game.scale_difficulty(scaling_moves, Game.balance.enemy_difficulty)


func _get_health_scaling():
 if id in Enemies.HEALTH_SCALING:
  return Enemies.HEALTH_SCALING[id]
 elif inherited_id != null:
  return Enemies.HEALTH_SCALING[inherited_id]
 else:
  return Enemies.HEALTH_SCALING[Enemies.FAT_CAT]


func _scale_health():
 var health_scaling = _get_health_scaling()

 var enemy_health = Game.balance.enemy_health
 var scaling_index = clamp(enemy_health, 0, health_scaling.size() - 1)

 max_health = health_scaling[scaling_index]
 health = max_health


func get_needed_parry():
 var words: WordList = word_builder.get_words()
 return max(moves[next_move].parry - words.maximum_length, 0)


func add_parry_intent():
 var words: WordList = word_builder.get_words()
 var parry = moves[next_move].parry
 if main.is_player_turn and words.maximum_length > 0:
  var needed_parry = get_needed_parry()
  if needed_parry == 0:
   add_intent(Intent.PARRY, {length = parry, parried = true})
  else:
   add_intent(Intent.PARRY, {length = parry, needed_length = needed_parry})
 else:
  add_intent(Intent.PARRY, {length = parry})


func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void :
 if "parry" in moves[next_move]:
  is_parried = words.maximum_length >= moves[next_move].parry


func _on_finished_updating_stats(_words):
 if "parry" in moves[next_move]:
  if main.is_player_turn:
   update_intents()


func _on_projectile_impacted():
 num_projectiles -= 1
 Game.screenshake(2, 0.24)


func append_scrabble_pool(multipliers, pool):
 var multiplier_pool = pool.duplicate()
 rng.move.shuffle(multiplier_pool)
 multipliers.append_array(multiplier_pool)


func show_above_board() -> void :
 reparent(main)


func return_below_board() -> void :
 reparent(main.enemy_marker)


func start_player_action() -> void :
 pass


func end_player_action() -> void :
 pass


func try_advance_cutscene() -> void :
 pass


func add_node_to_background(node: Node2D) -> Node2D:
 var clone: Node2D = CopyUtil.instantiate_clone(node)
 main.enemy_marker.add_child(clone)
 CopyUtil.copy_full(node, clone, true)
 clone.add_to_group("bg_free_offscreen")
 main.background.add_scrolling_node(clone)
 return clone



@warning_ignore("unused_parameter")
func apply_fish(tile: Tile, fish: Fish) -> void :
 pass



@warning_ignore("unused_parameter")
func apply_any_fish(tile: Tile, fish: Fish) -> void :
 pass


func get_save_data():
 var save = super.get_save_data()

 save.merge({
  next_move = next_move, 
  next_move_override = next_move_override, 
  last_move = last_move, 
  times_acted = times_acted, 
  times_performed_move = times_performed_move, 
 })

 return save


func load_save_data(save):
 super.load_save_data(save)
 next_move = save.next_move
 next_move_override = save.next_move_override
 last_move = save.last_move
 times_acted = save.times_acted
 times_performed_move = save.times_performed_move
 battle_started = true
