extends Status


const MAX_PARTICLE_DELAY = 10
const MIN_PARTICLE_DELAY = 2

var particle_delay = randf_range(MIN_PARTICLE_DELAY, MAX_PARTICLE_DELAY)

var dust_resource = preload("res://source/effects/haze_dust.tscn")

var timer: = GameTimer.new()

var turn_ending: = false
var rng: = RNG.new()


func _status_connect() -> void :
 Game.player.pre_turn_ended.connect(_on_player_pre_turn_ended)


func reseed(parent_rng: RNG) -> void :
 rng.reseed(parent_rng)


func _process(delta: float) -> void :
 if not tile_exists():
  return

 if tile.is_visible_in_tree():
  particle_delay -= delta

  if particle_delay <= 0:
   var dust = dust_resource.instantiate()
   particle_delay = randf_range(MIN_PARTICLE_DELAY, MAX_PARTICLE_DELAY)

   Game.get_particle_target(tile).add_child(dust)
   dust.global_position = tile.global_position + Vector2(
     randi_range(0, 10) * [1, -1].pick_random(), 
     randi_range(0, 10) * [1, -1].pick_random())

 if tile.is_preview or tile.is_projectile:
  return

 if timer.is_running():
  update_sprite_animation()
  if timer.get_elapsed_time() >= Game.balance.haze_time * 1000:
   timer.start()

   var apply_to = Game.tile_board.get_tiles({
    amount = 1, 
    effect_priority = Globals.AMBIVALENT_ENEMY_EFFECT_PRIORITY, 
    by_distance_from = tile.get_coord(), 
    max_distance = 1, 
    rng = rng, 
   })

   for new_tile: Tile in apply_to:
    new_tile.add_status(TileStatus.HAZE)
    new_tile.get_status(TileStatus.HAZE).reseed(rng)
    new_tile.add_poofcloud(tile.get_color())

   Game.main.game_state_updated.emit()


func get_sprite_animation():
 if turn_ending:
  return "haze_ticking_fast"

 var elapsed_time: = timer.get_elapsed_time()
 if not Game.main.is_player_turn or elapsed_time < 3 * 1000:
  return "idle"
 elif elapsed_time < 16 * 1000:
  return "haze_ticking"
 else:
  return "haze_ticking_fast"


func update_sprite_animation():
 if tile.sprite_anim_player.current_animation != get_sprite_animation():
  tile.sprite_anim_player.play(get_sprite_animation())


func apply(_data):
 if Game.main.is_player_turn:
  timer.start()


func _on_player_pre_turn_ended():
 turn_ending = true
 update_sprite_animation()


func get_save_data():
 return rng.get_save_data()


func load_save_data(save):
 rng.load_save_data(save)
 if Game.main.is_player_turn:
  timer.start()
