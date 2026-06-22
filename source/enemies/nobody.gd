extends Enemy

signal cutscene_finished
signal idle

var last_words_submitted: WordList
var waiting_for_idle: bool = false
var idle_bag: ShuffleBag
var last_idle: int = 1

var active_cutscene: StringManager.StringGroup = null
var active_cutscene_index: int = -1
var next_bubble_nobody: = true
var active_speech_bubble: SpeechBubble
var just_rerolled_board: = false

var cigarette_butt_scene = load("res://source/effects/cigarette_butt_projectile.tscn")
var breath_smoke_scene = load("res://source/effects/nobody_breath_smoke.tscn")


func _init():
 id = Enemies.NOBODY
 next_move = "expand_board"
 despawn_on_death = false
 hide_sprite_on_death = false
 keep_board_out = true

 moves = {

  expand_board = {
   next = "letter_opener", 
  }, 
  letter_opener = {
   cursed = {
    0: false, 
    3: true, 
   }, 
   next = "board_shear", 
  }, 
  board_shear = {
   damage = {
    0: 8, 
    1: 9, 
    2: 10, 
   }, 
   bleed = {
    0: 4
   }, 
   next = "expand_board", 
  }, 

  jubilist_a = {
   damage = {
    0: 1, 
    3: 2, 
   }, 
   count = {
    0: 3, 
    1: 4, 
    2: 5, 
   }, 
   next = "jubilist_b"
  }, 
  jubilist_b = {
   damage = {
    0: 5, 
    1: 6, 
    2: 8, 
   }, 
   next = "jubilist_a"
  }, 
  jubilist_phase_two = {
   next = "jubilist_c"
  }, 
  jubilist_c = {
   acid = {
    0: 4, 
    3: 5, 
   }, 
   bombs = {
    0: 1, 
    1: 2, 
   }, 
   slow_bombs = {
    0: 1, 
   }, 
   bigram_bombs = {
    0: 0, 
    2: 1, 
   }, 
   next = "jubilist_c"
  }, 
  jubilist_phase_three = {
   next = "jubilist_d"
  }, 
  jubilist_d = {
   next = "jubilist_e"
  }, 
  jubilist_e = {
   damage = {
    0: 10, 
    1: 15, 
    2: 20, 
    3: 26, 
   }, 
   next = "jubilist_d"
  }, 


  child_a = {
   next = "child_b"
  }, 
  child_b = {
   damage = {
    0: 6, 
    2: 8, 
   }, 
   cursed_periods = {
    0: false, 
    1: true, 
   }, 
   next = {
    0: "child_c", 
    3: "child_d", 
   }, 
  }, 
  child_c = {
   next = "child_d", 
  }, 
  child_d = {






   next = "child_a"
  }, 


  fishing = {
   cursed_odds = {
    0: 0.25, 
    1: 0.33, 
   }
  }, 
  fisher_a = {
   next = "fisher_b", 
   no_curse = true, 
  }, 
  fisher_b = {
   damage = {
    0: 1, 
    2: 2, 
   }, 
   cursed = {
    0: 0, 
    1: 1, 
   }, 
   next = "fisher_c", 
  }, 
  fisher_c = {
   damage = {
    0: 2, 
    2: 3, 
   }, 
   cursed = {
    0: 1, 
    1: 2, 
   }, 
   next = "fisher_d", 
  }, 
  fisher_d = {
   cursed = {
    0: 3, 
    2: 4, 
   }, 
   next = {
    0: "fisher_e", 
    3: "fisher_f", 
   }, 
  }, 
  fisher_e = {
   damage = {
    0: 2, 
    1: 3, 
    2: 4, 
   }, 
   count = 3, 
   next = "fisher_f", 
  }, 
  fisher_f = {
   damage = {
    0: 6, 
    1: 8, 
    2: 10, 
   }, 
   count = {
    0: 1, 
    3: 3, 
   }, 
   next = "fisher_b", 
  }, 










  addict_a = {
   haze = {
    0: 2, 
    3: 3, 
   }, 
   next = "addict_b", 
  }, 
  addict_b = {
   haze = {
    0: 2, 
    2: 3, 
    3: 4, 
   }, 




   next = "addict_c", 
  }, 
  addict_c = {
   damage = {
    0: 4, 
    1: 5, 
    2: 6, 
   }, 
   next = "addict_multitude", 
  }, 
  addict_multitude = {
   damage = {
    0: 8, 
    1: 10, 
    2: 12, 
    3: 14, 
   }, 
   haze = {
    0: 1, 
    1: 2, 
   }, 
   per_health = 2, 
   next = "addict_a", 
  }
 }


func _ready():
 super._ready()

 if launching_from_enemy_scene:
  Game.debug_character_select = true
  Game.return_to_menu.call_deferred()
  return

 if player.id == Globals.CHARACTERS.LEXICOGRAPHER:
  next_move = "expand_board"
 elif player.id == Globals.CHARACTERS.JUBILIST:
  next_move = "jubilist_b"
 elif player.id == Globals.CHARACTERS.CHILD:
  next_move = "child_a"
 elif player.id == Globals.CHARACTERS.FISHER:
  next_move = "fisher_a"
 elif player.id == Globals.CHARACTERS.ADDICT:
  next_move = "addict_a"

 tile_board.rerolled_board.connect(_on_board_rerolled)
 Game.player.pre_turn_ended.connect(_on_pre_player_turn_end)


func _get_health_scaling():
 if player.id == Globals.CHARACTERS.JUBILIST:
  var scaling = Enemies.NOBODY_HEALTH_SCALING[player.id]
  if next_move == "jubilist_phase_two":
   return scaling[1]
  elif next_move == "jubilist_phase_three":
   return scaling[2]
  else:
   return scaling[0]
 if player.id in Enemies.NOBODY_HEALTH_SCALING:
  return Enemies.NOBODY_HEALTH_SCALING[player.id]
 else:
  return Enemies.HEALTH_SCALING[id]


func display_intent():
 update_lexicographer_intents()
 update_child_intents()
 update_fisher_intents()
 update_addict_intents()
 update_jubilist_intents()


func play_battle_music(from_save: = false, _skipping_transition: = false) -> void :
 if from_save:
  super.play_battle_music(from_save)


func has_custom_battle_transition() -> bool:
 return true


func custom_battle_transition(_skipping: bool = false) -> void :
 await main.play_versus_text()
 anim_player.play_advance("approach")
 anim_player.queue("idle")
 await anim_player.pend_animation_stopped("approach")
 var cutscene: = pick_cutscene()
 if cutscene != "":
  await play_cutscene(cutscene)
 tile_board.stay_off_screen = false
 tile_board.prevent_filling = false
 tile_board.reset_board()
 super.play_battle_music()
 await tile_board.slide_in()
 await tile_board.fill_board()
 main.show_health()


func pick_cutscene() -> String:
 if not StringManager.has_string_group("nobody/%s" % player.id):
  return ""

 var file: = SaveManager.get_save()
 var character_group: = StringManager.get_string_group("nobody/%s" % player.id)
 var possible_cutscenes: Array[String] = []
 var unseen_cutscenes: Array[String] = []
 for group_name in character_group.groups:
  var cutscene: = character_group.groups[group_name]
  var can_play_cutscene: = true
  var cutscene_id: = cutscene.get_path_key()
  var has_viewed_cutscene: = file.has_viewed_nobody_cutscene(cutscene_id)

  if cutscene.has_string_at_path(["flags"]):
   var cutscene_flags: = cutscene.get_string_at_path(["flags"]).split(" ")
   if "pre_trans" in cutscene_flags and player.is_trans():
    can_play_cutscene = false
   elif "post_trans" in cutscene_flags and not player.is_trans():
    can_play_cutscene = false

   if "first_encounter" in cutscene_flags:
    if has_viewed_cutscene or Game.difficulty != 0 or not AchievementManager.can_unlock_progression():
     can_play_cutscene = false

   if "priority" in cutscene_flags and can_play_cutscene and not has_viewed_cutscene:
    unseen_cutscenes = [cutscene_id]
    break

  if can_play_cutscene:
   possible_cutscenes.append(cutscene_id)
   if not has_viewed_cutscene:
    unseen_cutscenes.append(cutscene_id)

 if not unseen_cutscenes.is_empty():
  possible_cutscenes = unseen_cutscenes
 elif SaveManager.get_skip_repeat_dialogue():
  return ""

 if possible_cutscenes.is_empty():
  return ""

 var random_cutscene: String = rng.move.pick_random(possible_cutscenes)
 return random_cutscene


func play_cutscene(cutscene_id: String) -> void :
 var cutscene: = StringManager.get_string_group(cutscene_id)
 SaveManager.get_save().set_viewed_nobody_cutscene(cutscene_id)
 is_playing_cutscene = true
 next_bubble_nobody = true
 active_cutscene = cutscene
 active_cutscene_index = -1
 advance_cutscene()
 if is_playing_cutscene:
  await cutscene_finished


func disappear_speech_bubble() -> void :
 if active_speech_bubble != null and is_instance_valid(active_speech_bubble):
  await active_speech_bubble.disappear()
  active_speech_bubble.queue_free()
  active_speech_bubble = null


func finish_cutscene() -> void :
 is_playing_cutscene = false
 await disappear_speech_bubble()
 active_cutscene = null
 active_cutscene_index = -1
 cutscene_finished.emit()


func advance_cutscene() -> void :
 active_cutscene_index += 1
 var str_index: = str(active_cutscene_index)
 if not active_cutscene.has_string_at_path([str_index]):
  await finish_cutscene()
  return

 var previous_bubble_nobody: = not next_bubble_nobody

 var line_flags: = PackedStringArray()
 if active_cutscene.has_string_group(str_index):
  if active_cutscene.has_string_at_path([str_index, "flags"]):
   line_flags = active_cutscene.get_string_at_path([str_index, "flags"]).split(" ")

 if "character" in line_flags:
  next_bubble_nobody = false
 elif "nobody" in line_flags:
  next_bubble_nobody = true

 var should_play_line: = true
 for flag in line_flags:
  if flag.begins_with("spell_"):
   should_play_line = false
   var spell_id: = flag.trim_prefix("spell_")
   for spell in player.get_spells():
    if spell.id == spell_id:
     should_play_line = true
     break

  if flag == "pro_piracy" and not Game.is_steam_inactive():
   should_play_line = false

 if not should_play_line:
  await advance_cutscene()
  return

 var new_bubble: = true
 if active_speech_bubble != null and is_instance_valid(active_speech_bubble):
  if next_bubble_nobody == previous_bubble_nobody:
   new_bubble = false
  else:
   await disappear_speech_bubble()

 if new_bubble:
  if next_bubble_nobody:
   active_speech_bubble = sprite.spawn_speech_bubble()
  else:
   active_speech_bubble = player.sprite.spawn_speech_bubble()

  if next_bubble_nobody:
   await active_speech_bubble.appear(&"appear_nobody")
  else:
   var frame: = Globals.CHARACTER_ORDER.find(player.id) + 2
   await active_speech_bubble.appear(&"appear_character", frame)

 next_bubble_nobody = not next_bubble_nobody

 var cutscene_string: = active_cutscene.get_string_at_path([str_index], {trans = player.is_trans()})
 var cutscene_control_string: = active_cutscene.get_string_at_path([str_index], {control = true, trans = player.is_trans()})
 active_speech_bubble.type_text(cutscene_string, cutscene_control_string, "cutoff" not in line_flags)

 if "cutoff" in line_flags:
  active_speech_bubble.text_playback.finished.connect(_cutoff_speech_bubble, ConnectFlags.CONNECT_ONE_SHOT)


func _cutoff_speech_bubble() -> void :
 active_speech_bubble.queue_free()
 active_speech_bubble = null
 advance_cutscene()


func try_advance_cutscene() -> void :
 if active_speech_bubble != null:
  if active_speech_bubble.is_typing_text():
   active_speech_bubble.cancel_typing_text()
   return
  elif active_speech_bubble.anim_player.is_playing():
   return

 await advance_cutscene()


func post_ready():
 sprite.particle_fastforward(8.0)


func prepare_first_turn():
 last_idle = 1
 setup_idle_bag()


func setup_idle_bag() -> void :
 var idle_rng: = RNG.new()
 idle_rng.reseed(rng.move)
 idle_bag = ShuffleBag.new([1, 2, 3], idle_rng)
 idle_bag.remove_from_bag(1)


func flinch_lethal(amount: int):
 tile_board.doomed_columns.clear()
 if player.id == Globals.CHARACTERS.JUBILIST:
  await flinch_lethal_jubilist(amount)
 else:
  await super.flinch_lethal(amount)


func animate_flinch_lethal():
 AudioManager.fade_music(0.1)
 sprite.particle_reset_velocity()
 anim_player.play_advance("die")


 await Game.timeout(4)


func end_battle_music() -> void :
 AudioManager.stop_music()


func animate_flinch(_damage):
 if word_builder.is_submitting:
  if last_words_submitted != null and last_words_submitted.words.size() > 0:
   play_morse(last_words_submitted.words)

 last_words_submitted = null

 sprite.particle_reset_velocity()

 var current_anim: = anim_player.assigned_animation
 var flinch_anim: = "flinch_" + current_anim

 if flinch_anim in anim_player.get_animation_list():
  anim_player.play(flinch_anim)
 else:
  anim_player.play("flinch_idle")

 anim_player.queue(current_anim)

 await pend_animation_played(current_anim)


func play_morse(words: PackedStringArray) -> void :
 for word in words:
  for character in word:
   var playback: = AudioManager.play_sound(Sounds.NOBODY_MORSE[character])
   await playback.finished


func apply_status(status, amount):
 var target_tiles = get_tiles({
  amount = amount, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
 })

 for tile in target_tiles:
  tile.add_status(status)
  tile.add_poofcloud(tile.get_color())

  await Game.timeout(0.08)


func end_player_action() -> void :
 if is_defeated:
  return

 if word_builder.is_submitting and will_damage_kill(word_builder.damage):
  return

 lexicographer_end_player_action()
 child_end_player_action()
 jubilist_end_player_action()
 addict_end_player_action()


func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void :
 last_words_submitted = words
 super._on_word_submitted(words, _damage, _ending_turn)


func _on_board_rerolled() -> void :
 if next_move == "jubilist_c":
  just_rerolled_board = true


func _on_pre_player_turn_end() -> void :
 if next_move == "addict_multitude" and not word_builder.is_submitting:
  update_intents()


func animate_attack() -> void :
 var smoke_break: = false
 if anim_player.assigned_animation == "smoke_break_idle":
  if anim_player.is_playing():
   await sprite.pend_flag("can_end", true)
  anim_player.play("smoke_break_end")
  smoke_break = true
 elif anim_player.assigned_animation == "time_to_lean_loop":
  if anim_player.is_playing():
   await sprite.pend_flag("can_end", true)
  anim_player.play("time_to_lean_end")

 else:
  anim_player.play("jog_papers")

 await sprite.hit

 if smoke_break:
  var parent_node: = get_tree().get_first_node_in_group("nobody_office_chunk")

  if parent_node != null:
   var projectile: ArcingProjectile = cigarette_butt_scene.instantiate()
   projectile.angular_velocity = PI * 10
   projectile.angular_deceleration = PI * 18
   projectile.decelerate_to = PI * 2
   projectile.rotation = randf_range(0.0, TAU)

   parent_node.add_child(projectile)

   var dest: = Util.random_point_in_collision_object(sprite.cigarette_target, Game.random)
   projectile.launch(sprite.cigarette_marker.global_position, dest, 80)

 animate_idle()


func play_idle(idle_id: int, instant: bool = false) -> void :
 if idle_id == 1:
  if instant:
   anim_player.play_advance("approach", true)

  anim_player.play("idle")
 elif idle_id == 2:
  anim_player.play_advance("smoke_break", instant)
  anim_player.queue("smoke_break_idle")
 else:
  if instant:
   anim_player.play("time_to_lean_loop")
  else:
   anim_player.play("time_to_lean")
   anim_player.queue("time_to_lean_loop")


func animate_idle() -> void :
 waiting_for_idle = true
 await anim_player.pend_animation_stopped(anim_player.assigned_animation)

 var next_idle: int = idle_bag.pop([last_idle])
 play_idle(next_idle)

 last_idle = next_idle

 waiting_for_idle = false
 idle.emit()


func wait_for_idle() -> void :
 if waiting_for_idle:
  await idle


func get_save_data():
 var save = super.get_save_data()
 save.idle_bag = idle_bag.get_save_data()
 save.idle = last_idle
 return save


func load_save_data(save):
 super.load_save_data(save)

 if "idle_bag" in save:
  idle_bag = ShuffleBag.new([1, 2, 3], null)
  idle_bag.load_save_data(save.idle_bag)
 else:
  setup_idle_bag()

 if "idle" in save:
  last_idle = save.idle
  play_idle(last_idle, true)
 else:
  last_idle = 1


func _on_sprite_event(event: String) -> void :
 super._on_sprite_event(event)
 if event == "smoke_recede":
  var smoke_anim_player: AnimPlayer = get_tree().get_first_node_in_group("nobody_smoke_anim_player")
  if smoke_anim_player != null:
   smoke_anim_player.play_advance("disappear")
 elif event == "breath_smoke":
  var target_node: SubViewport = get_tree().get_first_node_in_group("nobody_particle_target")
  var target_sprite: Sprite2D = get_tree().get_first_node_in_group("nobody_smoke_viewport_sprite")
  if target_node != null and target_sprite != null:
   var breath_smoke = breath_smoke_scene.instantiate()
   target_node.add_child(breath_smoke)
   breath_smoke.position = target_node.get_parent().to_local(sprite.breath_smoke_marker.global_position) - target_sprite.position



func update_lexicographer_intents() -> void :
 if next_move == "expand_board":
  add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 4})
 elif next_move == "letter_opener":
  add_intent(Intent.LETTER_OPENER, {cursed = moves.letter_opener.cursed})
 elif next_move == "board_shear":
  add_intent(Intent.ATTACK, {damage = moves.board_shear.damage})
  add_intent(Intent.BOARD_SHEAR, {count = moves.board_shear.bleed, size_x = 3, size_y = 4})


func expand_board():
 await animate_attack()
 await tile_board.set_size(5, 4)
 await wait_for_idle()


func letter_opener():
 var total_tile_value = 0
 var bottom_row = get_tiles({
  amount = 5, 
  rows = [0], 
  sorted = true, 
 })

 for tile in bottom_row:
  total_tile_value += tile.get_value()

 await animate_attack()

 if moves.letter_opener.cursed:
  for column in tile_board.get_column_coords():
   var queued_tile = tile_board.queue.get_preview(column, 0)
   if "statuses" in queued_tile:
    queued_tile.statuses.append(TileStatus.CURSED)
   else:
    queued_tile.statuses = [TileStatus.CURSED]

 tile_board.remove_tiles(bottom_row, {
  ignore_status = true, 
  delete_tiles = false, 
  settle = false, 
  restock = false, 
 })

 for tile: Tile in bottom_row:
  num_projectiles += 1
  var projectile_target: Vector2 = player.get_projectile_target()
  var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(0.0, 16.0)
  var target_pos: Vector2 = projectile_target + offset
  if num_projectiles > 1:
   target_pos += Vector2(-10, -10)

  tile.poof_smoke()

  var projectile: = tile.launch(
   tile.global_position, target_pos, 
   100, Vector2i.MIN, 1100, true, false, false, 
   func(poof_tile: Tile):
    poof_tile.poof_tile_smoke()
  )
  projectile.look_at_direction = false
  projectile.angular_velocity = PI * 10
  projectile.angular_deceleration = PI * 18
  projectile.decelerate_to = PI * 2
  if num_projectiles == 1:
   tile.impacted.connect( func():
    hit_player(total_tile_value)
   )
  tile.impacted.connect(_on_projectile_impacted)

  await Game.timeout(0.07)


 await tile_board.settle_board()
 await tile_board.fill_board()

 if num_projectiles > 0:
  await all_projectiles_impacted

 await wait_for_idle()


func board_shear():
 await animate_attack()

 hit_player(moves.board_shear.damage)
 await tile_board.set_size(3, 4)

 var rightmost_column = get_tiles({
  amount = moves.board_shear.bleed, 
  columns = [-1], 
 })

 for tile in rightmost_column:
  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)

 tile_board.doomed_columns.clear()
 await wait_for_idle()


func lexicographer_end_player_action() -> void :
 if next_move == "board_shear":
  tile_board.doomed_columns = [2, 3, 4]




func flinch_lethal_jubilist(amount: int):
 if next_move in ["jubilist_d", "jubilist_e"]:
  await super.flinch_lethal(amount)
  return

 if main.is_player_turn:
  triggering_player_turn_end = true

 is_flinching = true
 clear_intent()

 if word_builder.is_submitting:
  if last_words_submitted != null and last_words_submitted.words.size() > 0:
   play_morse(last_words_submitted.words)

 last_words_submitted = null

 sprite.particle_reset_velocity()

 anim_player.play_advance("die_fake")
 await anim_player.animation_finished

 await player.battle_end()

 anim_player.play("approach")

 if next_move in ["jubilist_a", "jubilist_b"]:
  next_move = "jubilist_phase_two"
 else:
  next_move = "jubilist_phase_three"

 await sprite.hit

 if next_move == "jubilist_phase_two":
  await tile_board.set_size(4, 4)
 elif next_move == "jubilist_phase_three":
  await tile_board.set_size(5, 4)

 await anim_player.pend_animation_stopped("approach")

 _scale_health()
 await health_bar.appear()

 Game.main.count_next_turn_as_battle_start = true

 await player.battle_start()

 animate_idle()

 is_flinching = false


func update_jubilist_intents():
 if next_move == "jubilist_a":
  add_intent(Intent.ATTACK, {damage = moves.jubilist_a.damage, count = moves.jubilist_a.count})
  if times_performed_move[next_move] != 0:
   add_intent(Intent.EXPAND_BOARD, {size_x = 4, size_y = 4})
 elif next_move == "jubilist_b":
  add_intent(Intent.ATTACK, {damage = moves.jubilist_b.damage})
  add_intent(Intent.SHRINK_BOARD, {size_x = 3, size_y = 4})
 elif next_move == "jubilist_c":
  add_intent(Intent.ACID_BOMB, {
   count = moves.jubilist_c.acid + moves.jubilist_c.bombs, 
   acid = moves.jubilist_c.acid, 
   bombs = moves.jubilist_c.bombs - moves.jubilist_c.bigram_bombs, 
   bomb_turns = "3" if moves.jubilist_c.bombs == 1 else "2-3", 
   bigram_bombs = moves.jubilist_c.bigram_bombs, 
  })
 elif next_move == "jubilist_d":
  add_intent(Intent.PREPARING)
 elif next_move == "jubilist_e":
  add_intent(Intent.ATTACK, {damage = moves.jubilist_e.damage})


func jubilist_a():
 await animate_attack()

 for i in moves.jubilist_a.count:
  hit_player(moves.jubilist_a.damage, i == moves.jubilist_a.count - 1)
  if i == moves.jubilist_a.count - 1 and tile_board.num_columns != 4:
   await tile_board.set_size(4, 4)

  await Game.timeout(0.24)

 await wait_for_idle()


func jubilist_b():
 await animate_attack()
 hit_player(moves.jubilist_b.damage)
 await tile_board.set_size(3, 4)
 tile_board.doomed_columns.clear()
 await wait_for_idle()


func jubilist_phase_two():
 pass


func jubilist_c():
 await animate_attack()

 var apply_acid = tile_board.get_tiles({
  amount = moves.jubilist_c.acid, 
  row_priority = tile_board.get_row_coords(true), 
  include_effects = [TileStatus.DEFAULT], 
  has_face = true, 
  no_final_shuffle = true, 
 })

 for tile in apply_acid:
  tile.add_status(TileStatus.ACID)
  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.08)

 await Game.timeout(0.5)

 var apply_bomb_anticheat = []
 if just_rerolled_board:
  apply_bomb_anticheat = get_tiles({
   amount = 1, 
   effect_priority = PURE_EFFECT_PRIORITY, 
   type_priority = TileType.DAMAGE, 
   custom_tile_check = func(tile: Tile, _parameters: Dictionary):
    var above_tile: = tile.get_board_neighbor(Vector2i(0, 1))
    if above_tile != null and above_tile.has_status(TileStatus.ACID):
     return true
    else:
     return false
  })

 just_rerolled_board = false

 var apply_bomb = get_tiles({
  amount = moves.jubilist_c.bombs - apply_bomb_anticheat.size(), 
  effect_priority = PURE_EFFECT_PRIORITY, 
  type_priority = TileType.DAMAGE, 
 })

 apply_bomb.append_array(apply_bomb_anticheat)

 if apply_bomb_anticheat.size() > 0:
  rng.move.shuffle(apply_bomb)

 var num_tiles: int = apply_bomb.size()
 for i in num_tiles:
  var tile: Tile = apply_bomb[i]
  tile.add_status(TileStatus.BOMB, 3 if i < moves.jubilist_c.slow_bombs else 2)
  if i < moves.jubilist_c.bigram_bombs:
   var bigram: = Letters.get_random_bigram(null, rng.move)
   tile.set_face(bigram)

  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.08)

 await wait_for_idle()


func jubilist_phase_three():
 pass


func jubilist_d():
 await animate_attack()
 await wait_for_idle()


func jubilist_e():
 await animate_attack()
 hit_player(moves.jubilist_e.damage)
 await wait_for_idle()


func jubilist_end_player_action() -> void :
 if next_move == "jubilist_b":
  tile_board.doomed_columns = [3]




func update_child_intents():
 if next_move == "child_a":
  add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 4})
 elif next_move == "child_b":

  add_intent(Intent.ATTACK, {damage = moves.child_b.damage})
  add_intent(Intent.CURSE_BOARD, {size_x = 6, size_y = 4})
 elif next_move == "child_d":
  add_intent(Intent.SHRINK_BOARD, {size_x = 4, size_y = 4})

func child_a():
 await animate_attack()
 await tile_board.set_size(5, 4)
 await wait_for_idle()


func child_b():
 await animate_attack()
 hit_player(moves.child_b.damage)

 var expand_mode = TileBoard.ExpandMode.BOTTOM_LEFT
 if moves.child_b.cursed_periods:
  await tile_board.set_size(4, 4)
  expand_mode = TileBoard.ExpandMode.CENTER

 for i in 4:
  tile_board.queue.insert_queued_tile_at({
   statuses = [TileStatus.CURSED, TileStatus.CAPITAL], 
   faces = [Letters.get_random_capital_letter(rng.move)]
  }, Vector2i(-1, 0))

  if moves.child_b.cursed_periods:
   tile_board.queue.insert_queued_tile_at({
    statuses = [TileStatus.CURSED, TileStatus.PERIOD], 
    faces = [Letters.get_random_period_letter(rng.move)]
   }, Vector2i(4, 0))

 await tile_board.set_size(6, 4, 1, null, false, 0.33, expand_mode)
 tile_board.doomed_columns.clear()
 await wait_for_idle()


func child_c() -> void :
 await Game.timeout(0.5)


func child_d() -> void :
 await animate_attack()
 await tile_board.set_size(4, 4, 1, null, false, 0.33, TileBoard.ExpandMode.CENTER)
 tile_board.doomed_columns.clear()
 await wait_for_idle()


func child_end_player_action() -> void :
 if next_move == "child_b" and moves.child_b.cursed_periods:
  tile_board.doomed_columns = [4]
 elif next_move == "child_d":
  tile_board.doomed_columns = [4, 5]




func update_fisher_intents():
 if "fisher" not in next_move:
  return

 var move_data = moves[next_move]
 if "damage" in move_data and move_data.damage > 0:
  if "count" in move_data:
   add_intent(Intent.ATTACK, {damage = move_data.damage, count = move_data.count})
  else:
   add_intent(Intent.ATTACK, {damage = move_data.damage})

 if "cursed" in move_data and move_data.cursed > 0:
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.CURSED, count = move_data.cursed})

 if next_move == "fisher_a" or next_move == "fisher_f":
  add_intent(Intent.CLEAR_BOARD)


func fisher_a():
 await animate_attack()
 await tile_board.set_size(4, 0, 0, 0)
 await Game.timeout(0.5)
 await tile_board.set_size(4, 5, 0, 0)
 await wait_for_idle()


func fisher_generic() -> void :
 var move_data = moves[next_move]

 var count = 1
 if "count" in move_data:
  count = move_data.count
 elif "damage" not in move_data and "cursed" not in move_data:
  await Game.timeout(0.5)
  return

 await animate_attack()

 for i in count:
  if "damage" in move_data and move_data.damage > 0:
   hit_player(move_data.damage, i == count - 1)

  if "cursed" in move_data and move_data.cursed > 0 and i == count - 1:
   var target_coords = get_tiles({
    amount = move_data.cursed, 
    rows = [-1], 
    get_coords = true, 
    empty = null, 
    sorted = true, 
   })

   num_projectiles = target_coords.size()

   for coord in target_coords:
    var tile = tile_board.create_tile()

    main.add_child(tile)
    tile.tile_sprite.is_fish = true
    tile.add_status(TileStatus.CURSED)
    tile.set_face(Letters.get_random_letter(tile_board.get_letter_census(), rng.move))

    tile.launch(sprite.cigarette_marker.global_position, tile_board.get_coord_position(coord), randf_range(48, 80), coord, 800, false, true)
    tile.impacted.connect(_on_projectile_impacted)

   if num_projectiles > 0:
    await all_projectiles_impacted

  if i != count - 1:
   await Game.timeout(0.33)

 await wait_for_idle()



func fisher_b():
 await fisher_generic()


func fisher_c():
 await fisher_generic()


func fisher_d():
 await fisher_generic()


func fisher_e():
 await fisher_generic()


func fisher_f():
 await fisher_generic()
 await fisher_a()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if "no_curse" not in moves[next_move]:
  if fish.rng.randf() <= moves.fishing.cursed_odds:
   tile.add_status(TileStatus.CURSED)
   if Game.balance.evil_fish_chance > 0.0:
    fish.is_evil = true
    fish.tile.tile_sprite.is_evil = true




func update_addict_intents():
 if next_move == "addict_a":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.HAZE, count = moves.addict_a.haze})
 elif next_move == "addict_b":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.HAZE, count = moves.addict_b.haze})
  add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 4})
 elif next_move == "addict_c":
  add_intent(Intent.ATTACK, {damage = moves.addict_c.damage})
 elif next_move == "addict_multitude":
  add_intent(Intent.CONCENTRATION, {
   damage = get_multitude_attack_damage(), 
   original_damage = moves.addict_multitude.damage, 
   reduce_by = 1, 
   per_health = moves.addict_multitude.per_health
  })
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.HAZE, count = moves.addict_multitude.haze})
  add_intent(Intent.SHRINK_BOARD, {size_x = 4, size_y = 4})


func addict_a():
 await animate_attack()
 await apply_status(TileStatus.HAZE, moves.addict_a.haze)
 await wait_for_idle()


func addict_b():
 await animate_attack()
 await tile_board.set_size(5, 4)
 await Game.timeout(0.5)
 await apply_status(TileStatus.HAZE, moves.addict_b.haze)
 await wait_for_idle()


func addict_c() -> void :
 await animate_attack()
 hit_player(moves.addict_c.damage)
 await wait_for_idle()


func addict_multitude():
 await animate_attack()
 hit_player(get_multitude_attack_damage())
 await tile_board.set_size(4, 4)
 await Game.timeout(0.5)
 await apply_status(TileStatus.HAZE, moves.addict_multitude.haze)
 tile_board.doomed_columns.clear()
 await wait_for_idle()


func get_multitude_damage_taken():
 var taken = damage_taken
 if not word_builder.is_submitting and main.is_player_turn:
  taken += word_builder.damage

 return taken


func get_multitude_damage_penalty():
 return max(0, get_multitude_damage_taken() / moves.addict_multitude.per_health)


func get_multitude_attack_damage():
 return max(0, moves.addict_multitude.damage - get_multitude_damage_penalty())


func _on_finished_updating_stats(_words):
 if main.is_player_turn and next_move == "addict_multitude":
  update_intents()


func addict_end_player_action() -> void :
 if next_move == "addict_multitude":
  tile_board.doomed_columns = [4]
