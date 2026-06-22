extends Enemy


var FreezerProjectile = preload("res://source/effects/freezer_projectile.tscn")
var freezer_projectile = null

var explode_animation: = "explode"

@onready var freezer_sprite = $Sprite / Sprite
@onready var mist_spawner = $Sprite / Sprite / MistSpawner
@onready var the_anim_player = $Sprite / TheFreezer / AnimPlayer


func _init():
 id = Enemies.FREEZER
 next_move = "first_crash"

 moves = {
  freeze = {
   frozen = 2, 
   next = "first_crash", 
  }, 
  first_crash = {
   custom_call = "crash", 
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   next = "crash", 
  }, 
  crash = {
   damage = {
    0: 6, 
    1: 7, 
    2: 8, 
    3: 9, 
   }, 
   next = "crash", 
  }, 
 }


func _process(_delta):
 sprite.hit_marker.global_position = freezer_sprite.global_position
 sprite.hit_marker.global_position.x -= 8


func display_intent():
 add_intent(Intent.ATTACK, {damage = moves[next_move].damage})
 add_intent(Intent.CONVERT_STATUS, {statuses = [TileStatus.FROZEN, TileEffect.WILDCARD], count = moves.freeze.frozen})


func animate_flinch(_damage):
 AudioManager.play_sound(Sounds.FREEZER.FLINCH)

 var start = freezer_sprite.global_position
 var dest = Vector2(global_position.x + 160, global_position.y)
 var height = 35

 clear_intent()
 await launch(start, dest, height)

 anim_player.play("appear")
 freezer_sprite.show()
 mist_spawner.show()

 if main.is_player_turn:
  await anim_player.animation_changed
  update_intents()


func animate_flinch_lethal():
 AudioManager.play_sound(Sounds.FREEZER.FLINCH)

 health_bar.disappear()

 var start = freezer_sprite.global_position
 var dest = Vector2(global_position.x + 60, global_position.y - 16)
 var height = 60

 the_anim_player.play("vanish")

 await launch(start, dest, height, false)
 Game.screenshake(8, 0.24)

 AudioManager.play_sound(Sounds.FREEZER.BOUNCE)

 await relaunch(
  freezer_projectile.global_position, 
  Vector2(global_position.x - 16, global_position.y - 8), 
  40)
 Game.screenshake(20, 0.32)

 freezer_projectile.queue_free()
 freezer_projectile = null

 anim_player.play("die")
 await anim_player.animation_finished
 await Game.timeout(0.5)


func launch(start, dest, height, free_on_impact = true):
 freezer_projectile = FreezerProjectile.instantiate()

 anim_player.stop()
 freezer_sprite.hide()
 mist_spawner.hide()

 main.add_child(freezer_projectile)

 post_launch()

 freezer_projectile.free_on_impact = free_on_impact

 freezer_projectile.launch(start, dest, height)
 await freezer_projectile.impacted

 if free_on_impact:
  freezer_projectile = null


func relaunch(start, dest, height):
 freezer_projectile.launch(start, dest, height)
 await freezer_projectile.impacted


func post_launch():
 pass


func freeze():
 var wildcards = get_tiles({
  amount = moves.freeze.frozen, 
  effect_priority = PURE_EFFECT_PRIORITY, 
  letters = ["*"], 
 })

 var apply_to = get_tiles({
  amount = moves.freeze.frozen - wildcards.size(), 
  effect_priority = PURE_EFFECT_PRIORITY, 
  exclude_letters = ["*"], 
 })

 apply_to += wildcards

 for tile in apply_to:
  var pause = randf_range(0.04, 0.08)
  await Game.timeout(pause)
  tile.set_face("*")
  tile.add_status(TileStatus.FROZEN)
  tile.add_poofcloud(Globals.COLORS.ICE)


func crash():
 if anim_player.current_animation == "appear":
  anim_player.clear_queue()
  await anim_player.animation_finished
 else:
  await sprite.animation_looped

 anim_player.play(explode_animation)

 await sprite.hit
 hit_player(moves[next_move].damage)
 Game.screenshake(10, 0.32)
 freeze()

 await pend_animation_stopped(explode_animation)


func hide_it() -> void :
 freezer_sprite.hide()
 if freezer_projectile != null:

  freezer_projectile.modulate = Color(0, 0, 0, 0)

 for mist in get_tree().get_nodes_in_group("freezer_mist"):
  mist.hide()

 intent_container.hide()


func show_it() -> void :
 freezer_sprite.show()
 if freezer_projectile != null:

  freezer_projectile.modulate = Color.WHITE

 for mist in get_tree().get_nodes_in_group("freezer_mist"):
  mist.show()

 intent_container.show()


func crash_game():
 hide_it()

 the_anim_player.play("appear")

 Game.word_builder.is_freezing = true

 var audio_playback = null
 var music_playback = null
 var audio_playback_position = -1.0
 var music_playback_position = -1.0
 if AudioManager.sound_player.has_stream_playback():
  audio_playback = AudioManager.sound_player.get_stream_playback()
  if audio_playback.is_playing():
   audio_playback_position = audio_playback.get_playback_position()

 if AudioManager.music_player.has_stream_playback():
  music_playback = AudioManager.music_player.get_stream_playback()
  if music_playback.is_playing():
   music_playback_position = music_playback.get_playback_position()

 await the_anim_player.animation_finished

 Game.main.process_mode = ProcessMode.PROCESS_MODE_DISABLED
 for i in 6:
  if audio_playback_position >= 0:
   audio_playback.seek(audio_playback_position)

  if music_playback_position >= 0:
   music_playback.seek(music_playback_position)

  await Game.timeout(0.5)

 Game.quit()


func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void :
 if "albatross" in words.words:
  await crash_game()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.1:
  tile.add_status(TileStatus.FROZEN)
