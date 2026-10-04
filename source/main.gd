class_name Main extends Node2D


signal player_action_started

signal game_state_updated

var is_battle = false
var is_player_turn = false
var count_next_turn_as_battle_start: = false
var forfeit_continuing: = false
var forfeit_quitting: = false
var showing_floor_end_continue: = false
var showing_act_end_summary: = false

var run_is_finished: = false

var tutorial: = Tutorial.new()

var player = null
var enemy = null

var last_enemy_id: String = ""

var persistent_data: Dictionary = {}

var mod_save_data: Dictionary = {}

var spell_pool = {}

var act = 0
var act_events = []

var kills = 0

var skipped_battle = false

var debug_save = null

var force_skip_transition = false
var toggling_pause: = false

var player_has_taken_turn: = false

var rng = {

 game = RNG.new(), 

 spell = RNG.new(), 

 enemy = RNG.new(), 

 champion = RNG.new(), 
}

var run_stats = RunStats.new()

@onready var SPELLS = Globals.SPELLS

@onready var player_marker = %PlayerMarker
@onready var enemy_marker = %EnemyMarker
@onready var word_builder = %WordBuilder
@onready var tile_board: TileBoard = %TileBoard
@onready var background: GameBG = $Background
@onready var background_particle_container: Node2D = %BackgroundParticleContainer
@onready var act_title = %ActTitle
@onready var act_subtitle = %ActSubtitle
@onready var tile_container = %TileContainer
@onready var projectile_container = %ProjectileContainer
@onready var submit_button = %SubmitButton
@onready var versus_label = %VersusLabel
@onready var black_bar_player = $GameUILayer / BlackBars / AnimPlayer
@onready var turn_timer = %AddictTimer
@onready var input_wall = %InputWall
@onready var menu_wall: ColorRect = %MenuWall
@onready var spell_container: SpellContainer = %SpellContainer
@onready var minigame_container = %MinigameContainer
@onready var screen_wipe = %ScreenWipe
@onready var spell_banner = %SpellBanner
@onready var game_menu_controller: MenuController = %GameMenuController
@onready var menu_controller: MenuController = %MenuController
@onready var spell_select: SpellSelect = %SpellSelect
@onready var summary_menu = %SummaryMenu
@onready var options_menu: MenuPanel = %OptionsMenu
@onready var player_info_bar: BattleUnitBar = %PlayerInfoBar
@onready var enemy_info_bar: BattleUnitBar = %EnemyInfoBar
@onready var above_menu_wall: Control = %AboveMenuWall
@onready var cutscene: CutscenePlayer = %Cutscene


func _init():
 Game.main = self


func _ready():
 StringManager.set_data_source("persistent_data", persistent_data)
 StringManager.set_data_source("run", {
  time = run_stats.get_total_deliberation_time
 })
 menu_controller.active.connect(game_state_updated.emit)
 menu_controller.inactive.connect(game_state_updated.emit)
 menu_controller.menu_appear_finish.connect(game_state_updated.emit.unbind(1))
 menu_controller.menu_disappear_start.connect(game_state_updated.emit.unbind(1))
 game_menu_controller.active.connect(game_state_updated.emit)
 game_menu_controller.inactive.connect(game_state_updated.emit)
 game_menu_controller.menu_appear_finish.connect(game_state_updated.emit.unbind(1))
 game_menu_controller.menu_disappear_start.connect(game_state_updated.emit.unbind(1))
 Game.spell_container = spell_container
 AchievementManager.unlocked_spell.connect(unlock_spell)
 start_run()
 Game.main_scene_loaded.emit()


func is_game_actionable(include_spell_select: = false, include_summary_continue: = false, include_tutorial: = false):
 if is_paused() or player.is_using_spell() or player.is_selecting() or not tile_board.idle or not word_builder.is_idle() or forfeit_quitting:
  return false

 if tutorial.active and tutorial.blocks_game_actions() and not include_tutorial:
  return false

 if summary_menu.active:
  return include_summary_continue

 if spell_select.active:
  return include_spell_select and not spell_select.select_completed

 return is_player_turn


func is_paused():
 return menu_controller.is_active() or toggling_pause or input_wall.visible


func can_toggle_pause(include_active_menu: = true) -> bool:
 return (
  not toggling_pause
  and (
   (include_active_menu and menu_controller.is_active())
   or is_game_actionable(true, true, true)
  ))


func toggle_pause():
 if not can_toggle_pause():
  return

 if menu_controller.is_active():
  toggling_pause = true
  game_state_updated.emit()
  await menu_controller.full_close()
  await spell_container.show_spells()
  toggling_pause = false
  game_state_updated.emit()
 elif is_game_actionable(true, true, true):
  toggling_pause = true
  game_state_updated.emit()
  await spell_container.hide_spells()
  await menu_controller.set_menu( %PauseMenu)
  toggling_pause = false
  game_state_updated.emit()


func get_expected_run_enemies():
 var rng_copy = RNG.new()
 rng_copy.set_seed(rng.game.seed)
 rng_copy.set_state(rng.game.state)

 var enemy_rng = RNG.new()
 enemy_rng.reseed(rng_copy)
 var champion_rng = RNG.new()
 champion_rng.reseed(rng_copy)

 var expected = []
 for act_index in Enemies.POOLS.size():
  var act_pool = Enemies.POOLS[act_index]
  var champions_unlocked = AchievementManager.champions_unlocked_for_act(act_index)
  for floor_pool in act_pool:
   var id = enemy_rng.pick_random(floor_pool)
   if id in Enemies.SHADOWS and champions_unlocked and champion_rng.randi_range(1, 3) == 3:
    id = Enemies.SHADOWS[id]

   expected.append(id)

 return expected


func reseed_guaranteeing_new_enemy():
 var unbeaten_enemies = []
 var unbeaten_champions = []
 var floors_with_unbeaten_enemies: int = 0
 var selected_save: = SaveManager.get_save()
 for act_index in Enemies.POOLS.size():
  var act_pool = Enemies.POOLS[act_index]
  var champions_unlocked = AchievementManager.champions_unlocked_for_act(act_index)
  for floor_pool in act_pool:
   var floor_has_unbeaten_enemy: = false
   for id in floor_pool:
    var stats = selected_save.get_enemy_stats(id, -1, false)
    if stats.kills == 0:
     unbeaten_enemies.append(id)
     if not floor_has_unbeaten_enemy:
      floors_with_unbeaten_enemies += 1
      floor_has_unbeaten_enemy = true

    if id in Enemies.SHADOWS and champions_unlocked:
     var champ_id = Enemies.SHADOWS[id]
     var champ_stats = selected_save.get_enemy_stats(champ_id, -1, false)
     if champ_stats.kills == 0:
      unbeaten_champions.append(champ_id)
      if not floor_has_unbeaten_enemy:
       floors_with_unbeaten_enemies += 1
       floor_has_unbeaten_enemy = true

 if unbeaten_enemies.is_empty() and unbeaten_champions.is_empty() and not tutorial.active:
  rng.game.reseed()
  return

 var try_for_enemies = unbeaten_enemies + unbeaten_champions

 if Enemies.CAT in unbeaten_enemies or tutorial.active:
  try_for_enemies = [Enemies.CAT]

 var target_new_enemies: int = mini(mini(try_for_enemies.size(), 3), floors_with_unbeaten_enemies)
 var most_new_enemies: int = 0
 var most_new_enemies_seed: int = -1
 var attempts: int = 0
 while attempts < 100:
  attempts += 1
  rng.game.reseed()
  var expected_enemies = get_expected_run_enemies()

  var new_enemies_included = []
  var new_enemies_in_seed: int = 0
  for id in try_for_enemies:
   if id in expected_enemies:
    new_enemies_included.append(id)
    new_enemies_in_seed += 1

  if new_enemies_in_seed >= target_new_enemies:
   return
  else:
   if new_enemies_in_seed > most_new_enemies:
    most_new_enemies = new_enemies_in_seed
    most_new_enemies_seed = rng.game.get_seed()

 if most_new_enemies > 0:
  rng.game.set_seed(most_new_enemies_seed)


func start_run():
 randomize()

 screen_wipe.cover()

 var loaded_from_save: = false
 if Game.loading_run_save:
  load_save_data(Game.loading_run_save)
  Game.loading_run_save = null
  loaded_from_save = true
 else:
  if (
    not SaveManager.get_save_data().seen_tutorial
    and Game.active_daily == null
    and Game.new_run_character == Globals.CHARACTERS.LEXICOGRAPHER
    and Game.debug_spawn_enemy == ""
    and Game.difficulty == 0
  ):
   if Util.is_mobile():
    SaveManager.get_save().set_viewed_tutorial(true)
   else:
    tutorial.start_tutorial()

  if Game.new_run_seed != null:
   rng.game.set_seed(Game.new_run_seed)
  else:
   reseed_guaranteeing_new_enemy()

  if Game.debug_spawn_enemy != "":
   act = get_enemy_act(Game.debug_spawn_enemy)

  background.set_background_for_act(act)

  background.initialize_layers()

  rng.enemy.reseed(rng.game)
  rng.champion.reseed(rng.game)
  background.reseed(rng.game)

  if Game.debug_spawn_enemy == Enemies.NOBODY:
   debug_play_nobody_pattern()
  else:
   background.play_pattern("loop", true)

  spell_select.reseed(rng.game)
  rng.spell.reseed(rng.game)
  tile_board.reseed(rng.game)
  Game.update_balance_vars()
  AchievementManager.reset_run_data()
  spawn_player(Game.new_run_character)
  player.reseed(rng.game)

  tile_board.set_size(4, 4, null, null, true, 0.0)

  if not tutorial.active:
   add_starting_spells()
  else:
   spell_container.position_spells()

  fill_spell_pool()

  queue_character_cutscene_if_applicable("first_run")
  if AchievementManager.can_unlock_progression():
   if Game.difficulty >= 1:
    queue_cutscene_if_not_viewed("black/first_run")

   if Game.difficulty == 10:
    queue_cutscene_if_not_viewed("hazel_clearance/first_run")

  if cutscene.has_queued_cutscene():
   cutscene.play_queued_cutscene()
   await cutscene.finished

  tile_board.initialize_crit_chance()
  tile_board.reset_board()
  tile_board.slide_out(true)

  start_game_loop()

 Bridge.set_rich_presence_key("character", StringManager.get_string("character/" + player.id + "/title"))
 var difficulty_name: = StringManager.get_string("difficulty/" + str(Game.difficulty) + "/name")
 var difficulty_or_daily: = difficulty_name
 if Game.active_daily:
  difficulty_or_daily = StringManager.get_string("menu/main/daily")

 Bridge.set_rich_presence_key("difficulty", difficulty_name)
 Bridge.set_rich_presence_key("difficulty_or_daily", difficulty_or_daily)


 game_state_updated.emit()

 %PauseButton.update_frame()

 run_stats.play_timer.start()

 await screen_wipe.wipe_out()

 AchievementManager.started_run()

 if loaded_from_save and is_battle:
  if Game.player.id == Globals.CHARACTERS.ADDICT and not forfeit_continuing:
   force_end_player_turn()
  else:
   start_player_action(false)

 forfeit_continuing = false


func add_starting_spells(gain: bool = false) -> void :
 var starting_spells = player.starting_spells
 if not Game.debug_spawn_spells.is_empty():
  starting_spells = starting_spells + Game.debug_spawn_spells
  Game.debug_spawn_spells.clear()

 for spell_id in starting_spells:
  if AchievementManager.should_track_stats():
   var save: = SaveManager.get_save()
   save.track_spell_found(spell_id, Game.difficulty)
   save.track_spell_taken(spell_id, Game.difficulty)

  var spell: = Spell.create(spell_id)
  spell._first_spawn()
  if Game.balance.cursed_starting_spells:
   spell.set_curse(Globals.SPELL_CURSES.CURSED)
  spell_container.add_spell(spell)
  spell.add_charge(99)

  if gain:
   var player_spell: PlayerSpell = spell_container.find_spell(spell)
   player_spell.spell_paper.gain()


func fill_spell_pool():
 spell_pool = Globals.get_spell_pool()

 if Game.active_daily and player.id != Globals.CHARACTERS.JUBILIST:
  for fixed_spell in Game.active_daily.get_forced_spells():
   spell_pool.erase(fixed_spell)

 for spell in player.get_spells():
  remove_spell_from_pool(spell.id)

 if player.has_red_letter_spell():
  remove_spell_from_pool(SPELLS.RED_LETTER)



func unlock_spell(spell):
 if Game.active_daily:
  return

 if spell not in spell_pool and spell in Globals.SPELL_POOL:
  spell_pool[spell] = Globals.SPELL_POOL[spell] * 2


func remove_spell_from_pool(spell_id):
 if spell_id != SPELLS.LETTER_STAMP:
  spell_pool.erase(spell_id)


func get_enemy_act(enemy_id):
 var act_and_floor = Enemies.get_act_and_floor(enemy_id)
 if act_and_floor == null:
  return 0
 else:
  return act_and_floor.act


func start_game_loop():
 force_skip_transition = not Game.running_from_menu
 change_floor()


func generate_act():
 act_events = []

 for stage_pool in Enemies.POOLS[act]:
  var use_pool = stage_pool.duplicate()

  if Game.debug_spawn_enemy != "":
   if Enemies.enemy_in_pool(Game.debug_spawn_enemy, stage_pool):
    act_events.append({enemy = Game.debug_spawn_enemy, debug = true})
    continue

  if Game.active_daily:
   Game.active_daily.modify_enemy_pool(use_pool)
  else:
   var encountered_enemies: Array[String] = []
   var unencountered_enemies: Array[String] = []
   for id in use_pool:
    var stats = SaveManager.get_save().get_enemy_stats(id, -1, false)
    if stats.encounters == 0:
     unencountered_enemies.append(id)
    else:
     encountered_enemies.append(id)

   var priority_pool: Array[String] = []
   for id in Enemies.PRIORITY_ENCOUNTERS:
    if id in use_pool and id in unencountered_enemies:
     priority_pool.append(id)

   if not priority_pool.is_empty():
    use_pool = priority_pool
   elif encountered_enemies.size() == 0:
    for id in Enemies.DEPRIORITY_ENCOUNTERS:
     if id in use_pool:
      use_pool.erase(id)

  var enemy_name = rng.enemy.pick_random(use_pool)
  act_events.append({enemy = enemy_name})

 var num_spell_selections = 2

 var spell_select_locations = [1, 2, 3]
 if num_spell_selections == 1:
  spell_select_locations = [1, 2]

 if not SaveManager.get_save_data().seen_first_spell_select and not Game.active_daily:
  spell_select_locations = [2, 3]

 rng.game.shuffle(spell_select_locations)
 spell_select_locations = spell_select_locations.slice(0, num_spell_selections)

 spell_select_locations.sort_custom( func(a, b): return a > b)

 var spell_select_index: = spell_select_locations.size() - 1
 for index in spell_select_locations:
  act_events.insert(index, {spell_select = true, spell_select_index = spell_select_index})
  spell_select_index -= 1

 if Game.debug_spawn_enemy != "":
  var enemy_index: = 0
  for i in act_events.size():
   if act_events[i].get("enemy", "") == Game.debug_spawn_enemy:
    enemy_index = i
    break

  Game.debug_spawn_enemy = ""
  act_events = act_events.slice(enemy_index)



func display_act():
 act_title.text = StringManager.get_string("misc/act_" + str(act) + "/title")
 act_subtitle.text = StringManager.get_string("misc/act_" + str(act) + "/subtitle")

 act_title.visible_characters = 0
 act_subtitle.visible_characters = 0
 act_title.show()
 act_subtitle.show()

 await Game.timeout(1)

 await Game.type_text_with_audio(act_title)
 await Game.timeout(0.5)
 await Game.type_text_with_audio(act_subtitle)

 await Game.timeout(2)

 await Game.type_text_with_audio(act_subtitle, 0.04, -1)
 await Game.type_text_with_audio(act_title, 0.04, -1)
 act_subtitle.hide()
 act_title.hide()


func change_floor():
 var skipping_transition = force_skip_transition
 force_skip_transition = false
 if act_events.size() == 0:
  generate_act()

  if not skipping_transition:
   display_act()

 var event = act_events[0]
 var debug_spawning_enemy = "debug" in event
 if "spell_select" in event:
  spell_select.generate_spells(act, event.get("spell_select_index", -1))
  game_menu_controller.set_menu(spell_select)
  return

 var is_fixed_enemy: = false
 var shadows_disabled: = false
 if Game.active_daily:
  is_fixed_enemy = Game.active_daily.is_forced_enemy(event.enemy)
  shadows_disabled = Game.active_daily.are_shadows_disabled(act)

 if (
   not debug_spawning_enemy
   and not is_fixed_enemy
   and not shadows_disabled
   and event.enemy in Enemies.SHADOWS
 ):
  var champions_unlocked = AchievementManager.champions_unlocked_for_act(act)
  var should_be_shadow: bool = rng.champion.randi_range(1, 3) == 3
  if Game.active_daily and Game.active_daily.are_shadows_forced(act):
   should_be_shadow = true

  if champions_unlocked and should_be_shadow:
   event.enemy = Enemies.SHADOWS[event.enemy]

 var spawning_enemy = event.enemy
 if not skipping_transition:
  background.start_scrolling()
  player.start_walking()

  if spawning_enemy == Enemies.NOBODY:
   if player.health_bar.visible:
    player.health_bar.disappear()

   if not tile_board.is_slid_out:
    tile_board.slide_out(true)

  if spawning_enemy == Enemies.NOBODY or spawning_enemy == Enemies.BRUTALIST:
   background.start_scrolling(999.0)
   player.start_walking()
   background.play_pattern(spawning_enemy)
   await background.enemy_spawn_triggered
   spawn_enemy(spawning_enemy)
   enemy.global_position.x = background.enemy_spawn_position.x
   enemy.reseed(rng.game)
   enemy.post_ready()
   enemy.start_appearing()
   background.add_scrolling_node(enemy)

   if spawning_enemy == Enemies.NOBODY:
    await background.almost_stopped_scrolling
    player.stop_walking()
    await background.stopped_scrolling
    background.remove_scrolling_node(enemy)
    enemy.position = Vector2.ZERO
   else:
    await background.stopped_scrolling
    background.remove_scrolling_node(enemy)
    enemy.position = Vector2.ZERO
    player.feint()
    Game.screenshake(10, 0.5)
    await Game.timeout(0.66)
  else:
   background.start_scrolling()
   player.start_walking()

   var is_scrolling_node: bool = false
   if spawning_enemy not in Enemies.AMBUSH:
    spawn_enemy(spawning_enemy)

    enemy.position.x = background.scroll_destination
    enemy.reseed(rng.game)
    enemy.post_ready()
    enemy.start_appearing()
    background.add_scrolling_node(enemy)
    is_scrolling_node = true

   await background.almost_stopped_scrolling
   player.stop_walking()

   await background.stopped_scrolling

   if is_scrolling_node:
    background.remove_scrolling_node(enemy)
    enemy.position = Vector2.ZERO

 if skipping_transition or spawning_enemy in Enemies.AMBUSH:
  spawn_enemy(spawning_enemy)
  enemy.reseed(rng.game)
  enemy.post_ready()

 await enemy.appear()

 if player.is_flinching:
  await player.recompose()

 start_battle(skipping_transition)


func is_last_floor():
 return act_events.size() == 1


func get_next_act():
 if act == 2:
  return 0
 else:
  return act + 1


func increment_floor():
 var last_event = act_events[0]
 if "enemy" in last_event:
  if last_event.enemy in Enemies.BOSSES:
   if player.id == Globals.CHARACTERS.CHILD:
    await player.heal(Game.balance.boss_healing_child)
   else:
    await player.heal(Game.balance.boss_healing)

   await AchievementManager.process_unlock_queue()

 if not is_last_floor():
  act_events.remove_at(0)
  return

 var next_act = get_next_act()
 act_events = []
 act = next_act

 screen_wipe.wipe()
 await screen_wipe.screen_covered
 background.set_background_for_act(act)
 background.initialize_layers()
 background.play_pattern("loop")


func generate_leaderboard_entry(victory: = false, forfeit: = false) -> Bridge.LeaderboardEntry:
 var leaderboard_entry: = Bridge.LeaderboardEntry.create()
 var longest_words = run_stats.get_longest_words()
 if longest_words.size() > 0:
  leaderboard_entry.longest_word = longest_words[0]

 leaderboard_entry.forfeited = forfeit
 leaderboard_entry.died = not victory and not forfeit
 leaderboard_entry.last_enemy = last_enemy_id
 leaderboard_entry.kills = kills
 leaderboard_entry.time_taken = run_stats.get_total_deliberation_time()
 leaderboard_entry.turns_taken = run_stats.turns_taken
 leaderboard_entry.damage_taken = AchievementManager.total_damage_taken

 for spell: Spell in player.get_spells():
  var id: String = spell.secret_id if spell.secret_id != "" else spell.id
  leaderboard_entry.spells.append(id)
  leaderboard_entry.spell_data.append(spell.get_binary_data())

 return leaderboard_entry


func queue_character_cutscene_if_applicable(character_cutscene: String) -> void :
 if AchievementManager.can_unlock_progression():
  var cutscene_id: String = player.id + "/" + character_cutscene
  queue_cutscene_if_not_viewed(cutscene_id)


func queue_cutscene_if_not_viewed(cutscene_id: String) -> void :
 if Game.debug_spawn_enemy != "":
  return

 if not StringManager.has_string_group("cutscenes/" + cutscene_id):
  push_warning("Cutscene ", cutscene_id, " does not exist!")
  return

 var save: = SaveManager.get_save()
 if not save.has_viewed_cutscene(cutscene_id):
  cutscene.queue_cutscene(cutscene_id)
  save.track_viewed_cutscene(cutscene_id)


func finish_run(is_victory: = false):


 if is_victory:
  Bridge.set_rich_presence_display("#Victory")
  AchievementManager.completed_run()
 else:
  if enemy:
   Bridge.set_rich_presence_display("#GameOver")
  else:
   Bridge.set_rich_presence_display("#GameOverEnemyless")

  AchievementManager.player_died()

 if AchievementManager.should_track_stats():
  if is_victory:
   SaveManager.get_save().track_win_time(run_stats.get_total_deliberation_time(), player.id, Game.difficulty)

  if enemy and not is_victory:
   SaveManager.get_save().track_enemy_loss(enemy.id, Game.difficulty)

 if Game.active_daily and not Game.debug_run and Bridge.version_has_leaderboards():
  var entry: = generate_leaderboard_entry(is_victory, false)
  await Bridge.try_upload_score(Game.active_daily.get_identifier(), entry)

 if is_victory:
  queue_character_cutscene_if_applicable("first_win")
  if AchievementManager.can_unlock_progression():
   if player.id == Globals.CHARACTERS.ADDICT and run_stats.get_total_deliberation_time() <= (1000 * 60 * 10) + 999:
    queue_cutscene_if_not_viewed("addict/speedrun")

   var all_characters_completed: = true
   var all_red_clearance_completed: = true
   var all_hazel_clearance_completed: = true
   for character in Globals.CHARACTERS.values():
    if not AchievementManager.has_achievement(Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS[character], 1):
     all_characters_completed = false

    if not AchievementManager.has_achievement(Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS[character], 10):
     all_red_clearance_completed = false

    if not AchievementManager.has_achievement(Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS[character], 11):
     all_hazel_clearance_completed = false

   if all_characters_completed:
    queue_cutscene_if_not_viewed("black/first_win")

   if Game.difficulty == 10:
    queue_cutscene_if_not_viewed("hazel_clearance/first_win")
    if all_hazel_clearance_completed:
     queue_cutscene_if_not_viewed("hazel_clearance/last_win")

   if all_characters_completed:
    queue_cutscene_if_not_viewed("extra/credits")

   if Game.difficulty >= 9:
    if all_red_clearance_completed and not cutscene.is_cutscene_queued("extra/credits"):
     queue_cutscene_if_not_viewed("extra/credits_red")

 SaveManager.get_save().store_file()

 run_is_finished = true

 if Game.active_daily:
  SaveManager.get_save().clear_saved_daily()
 else:
  SaveManager.get_save().clear_saved_run()

 await AchievementManager.process_unlock_queue()

 if is_victory:
  AudioManager.play_sound(Sounds.STINGERS.VICTORY)
  show_summary(act, true, is_victory)
 else:
  AudioManager.stop_music()
  AudioManager.play_sound(Sounds.STINGERS.GAME_OVER)
  show_summary(-1, true, is_victory)

 await game_menu_controller.inactive

 Game.exiting_to_menu = true
 await screen_wipe.wipe_in()

 if cutscene.has_queued_cutscene():
  cutscene.play_queued_cutscene()
  await cutscene.finished

 Game.return_to_menu()


func show_summary(summary_act: int = -1, show_run: bool = false, is_victory: bool = true, instant: bool = false) -> void :
 summary_menu.show_summary(summary_act, show_run, is_victory)
 game_menu_controller.set_menu(summary_menu, instant)


func show_act_end_summary(instant: = false) -> void :
 showing_act_end_summary = true
 show_summary(act, false, true, instant)


func show_floor_end_continue(instant: = false) -> void :
 showing_floor_end_continue = true

 summary_menu.show_continue()
 game_menu_controller.set_menu(summary_menu, instant)


func board_should_come_back() -> bool:
 if tile_board.stay_off_screen:
  return false

 if player.is_defeated:
  return false

 if is_battle and enemy != null and not enemy.is_defeated:
  return true

 if act_events.size() > 1 and "spell_select" in act_events[1]:
  return false

 if act_events.size() == 1:
  return false

 return true


func end_floor(show_addict_continue: = true):
 if is_last_floor():
  if act == 2:
   finish_run(true)
   return
  elif not force_skip_transition:
   show_act_end_summary()
 elif Game.player.id == Globals.CHARACTERS.ADDICT and show_addict_continue:
  show_floor_end_continue()
 else:
  await increment_floor()
  change_floor()


func set_battle_rich_presence():
 var enemy_name: String = enemy.get_unit_name()
 Bridge.set_rich_presence_key("enemy", enemy_name)
 if Game.active_daily:
  Bridge.set_rich_presence_display("#InDaily")
 else:
  Bridge.set_rich_presence_display("#InRun")


func show_health() -> void :
 if not player.health_bar.visible:
  player.show_health()
  await Game.timeout(0.16)

 enemy.show_health()


func play_versus_text() -> void :
 var enemy_name: String = enemy.get_unit_name()
 var player_name: = StringManager.get_string("character/" + player.id + "/title")

 versus_label.text = StringManager.get_string("misc/versus_label", {character = player_name, enemy = enemy_name})
 versus_label.visible_characters = 0
 versus_label.show()
 await Util.type_text(versus_label, 0.025)
 await Game.timeout(1)
 await Util.type_text(versus_label, 0.02, -1)
 versus_label.hide()



func start_battle(skipping_transition = false):
 is_battle = true

 enemy.pre_start_battle()

 if Game.debug_enemy_health != -1:
  enemy.health = Game.debug_enemy_health
  Game.debug_enemy_health = -1

 if Game.debug_player_health != -1:
  player.health = Game.debug_player_health
  Game.debug_player_health = -1

 enemy.play_battle_music(false, skipping_transition)

 set_battle_rich_presence()

 run_stats.start_tracking_encounter(enemy.id, act, player.health)

 if tile_board.is_slid_out and not enemy.keep_board_out:
  await tile_board.slide_in()

 await tile_board.fill_board()

 SaveManager.get_save().track_enemy_encounter(enemy.id, Game.difficulty)

 if enemy.has_custom_battle_transition():
  await enemy.custom_battle_transition(skipping_transition)
 else:
  show_health()

  if not skipping_transition:
   await play_versus_text()

 await enemy.start_battle()

 await player.battle_start()

 start_player_turn(true)


func spawn_player(id):
 Game.player = load("res://source/characters/" + id + ".tscn").instantiate()
 player = Game.player

 player.action_finished.connect(_on_player_action_finished)
 player.rerolled.connect(_on_player_rerolled)

 player_marker.add_child(player)

 player_info_bar.set_battle_unit(player)
 player.set_intent_container( %PlayerIntentContainer)

 if id == Globals.CHARACTERS.ADDICT:
  turn_timer.enable()


func spawn_enemy(enemy_name):
 if enemy_name.get_extension() != "tscn":
  enemy_name = "res://source/enemies/" + enemy_name + ".tscn"

 var enemy_scene = load(enemy_name)
 enemy = enemy_scene.instantiate()

 Game.enemy = enemy
 last_enemy_id = enemy.id

 enemy.action_finished.connect(_on_enemy_action_finished)
 enemy_marker.add_child(enemy)
 enemy_info_bar.set_battle_unit(enemy)
 enemy.set_intent_container( %EnemyIntentContainer)


func end_battle(force_despawn_enemy: bool = false):
 is_battle = false
 is_player_turn = false
 game_state_updated.emit()
 kills += 1
 player.bruise = 0
 player.defense = 0
 word_builder.slot_multipliers = []
 word_builder.word_holder.hide_slots(false, true)
 Game.stop_turn_timers.emit()
 await player.battle_end()
 run_stats.stop_tracking_encounter(player.health)

 enemy.end_battle_music()

 if force_despawn_enemy or enemy.despawn_on_death:
  despawn_enemy()

 await tile_board.battle_end()

 end_floor()


func start_player_turn(is_battle_start: bool = false):
 player.defense = 0
 player.bruise = 0

 await player.turn_start(is_battle_start)
 AchievementManager.start_player_turn()
 await AchievementManager.process_unlock_queue()

 run_stats.track_turn()

 if forfeit_quitting:
  save_and_exit()
 else:
  start_player_action()


func start_player_action(show_slots: = true):
 run_stats.play_timer.start()
 save_run()

 if show_slots and word_builder.slot_multipliers.size() != 0:
  await word_builder.word_holder.show_slots()

 await enemy.start_player_action()

 if turn_timer.enabled:
  turn_timer.appearing = true
  turn_timer.time_scale = 1
  await Game.timeout(1.0)
  turn_timer.appearing = false

 is_player_turn = true
 game_state_updated.emit()
 Game.start_turn_timers.emit()
 player_action_started.emit()


func start_ending_player_turn(ignore_spell_use: bool = false, submit_word_builder_if_possible: = true) -> void :
 is_player_turn = false
 player_has_taken_turn = true
 game_state_updated.emit()
 Game.stop_turn_timers.emit()
 Game.player.pre_turn_ended.emit()

 if menu_controller.is_active():
  await menu_controller.try_full_close()
  await spell_container.show_spells()

 var minigames: = get_tree().get_nodes_in_group(&"minigame")
 for minigame: Minigame in minigames:
  minigame.cancel()

 if player.is_selecting():
  player.cancel_selection()
 elif player.is_using_spell() and not ignore_spell_use:
  await player.stopped_using_spell

 var submit_word_builder: = false
 if not word_builder.is_submitting:
  if submit_word_builder_if_possible and word_builder.can_submit():
   submit_word_builder = true
   word_builder.is_submitting = true
  else:
   await word_builder.remove_tiles()
   word_builder.update_stats()
   await tile_board.wait_for_idle_tiles()
   await Game.timeout(0.5)

 await word_builder.on_player_turn_ending()
 await enemy.end_player_action()

 if submit_word_builder:
  word_builder.confirm_word()


func _on_player_action_finished():
 end_player_turn()


func _on_player_rerolled():
 end_player_turn(true)


func check_battle_ended():
 if player.is_dead:
  if enemy != null:
   enemy.clear_intent()

  word_builder.intent_container.clear_intents()

  await player_death()
  return true

 if enemy.is_defeated:
  await enemy_death()
  return true

 return false


func player_death():
 run_stats.stop_tracking_encounter(0)

 if player.is_flinching:
  await player.stopped_flinching

 if enemy != null:
  await enemy.health_bar.disappear()

 await finish_run(false)


func enemy_death():
 SaveManager.get_save().track_enemy_kill(enemy.id, Game.difficulty)

 tile_board.clear_targets()

 AchievementManager.enemy_died()
 await AchievementManager.process_unlock_queue()

 end_battle()


func end_player_turn(reroll = false):
 is_player_turn = false
 game_state_updated.emit()
 Game.stop_turn_timers.emit()

 await player.end_turn()

 AchievementManager.turn_ended()

 if not player.is_dead:
  await AchievementManager.process_unlock_queue()
  await tile_board.turn_end(reroll)

 await player.recompose()

 var is_battle_ended = await check_battle_ended()

 if not is_battle_ended:
  start_enemy_turn()


func force_end_player_turn(ignore_spell_use: = false, submit_word_builder_if_possible: = true) -> void :
 await start_ending_player_turn(ignore_spell_use, submit_word_builder_if_possible)

 if not word_builder.is_submitting:
  end_player_turn()


func start_enemy_turn():
 await Game.timeout(0.3)
 enemy.act()


func _on_enemy_action_finished():
 await player.recompose()
 await tile_board.enemy_turn_end()
 await player.recompose()
 end_enemy_turn()


func end_enemy_turn():
 await enemy.end_turn()

 if enemy.is_flinching:
  await enemy.stopped_flinching

 await AchievementManager.process_unlock_queue()

 var is_battle_ended = await check_battle_ended()
 if not is_battle_ended:
  if count_next_turn_as_battle_start:
   count_next_turn_as_battle_start = false
   start_player_turn(true)
  else:
   start_player_turn()


func get_active_minigame() -> Minigame:
 var minigames: = get_tree().get_nodes_in_group(&"minigame")
 if minigames.is_empty() or minigames[0].is_queued_for_deletion():
  return null
 else:
  return minigames[0]


func _on_spell_select_completed() -> void :
 await game_menu_controller.inactive
 if spell_select.is_debug_select:
  spell_select.is_debug_select = false
  return

 end_floor(false)


func _on_summary_menu_finished() -> void :
 if showing_act_end_summary or showing_floor_end_continue:
  showing_act_end_summary = false
  showing_floor_end_continue = false

  await game_menu_controller.inactive
  await Game.timeout(0.3)
  await increment_floor()
  change_floor()


func spell_in_pool(spell: String) -> bool:
 return spell in spell_pool


func pick_random_spell(exclude_spells = [], force_spells = [], include_spells = []):

 if spell_pool.size() < 3:
  fill_spell_pool()

 var pool_copy = spell_pool.duplicate()

 for id in force_spells:
  if id not in pool_copy:
   pool_copy[id] = 1.0

 for id in exclude_spells:
  pool_copy.erase(id)

 var has_forced_spell: = false
 for id in force_spells:
  if id in pool_copy:
   has_forced_spell = true
   break

 if has_forced_spell or not include_spells.is_empty():
  for id in pool_copy.keys():
   if has_forced_spell:
    if id not in force_spells:
     pool_copy.erase(id)
   elif not include_spells.is_empty() and id not in include_spells:
    pool_copy.erase(id)



 if pool_copy.is_empty():
  fill_spell_pool()
  return pick_random_spell(exclude_spells)

 var spell_id = rng.spell.weighted_random(pool_copy)
 remove_spell_from_pool(spell_id)

 return spell_id


func compare_word_value(wordA, wordB):
 var valueA = 0
 var valueB = 0

 for letter in wordA:
  valueA += Letters.LETTER_VALUES[letter]

 for letter in wordB:
  valueB += Letters.LETTER_VALUES[letter]

 return valueA > valueB


func despawn_player():
 player_marker.remove_child(player)
 player.queue_free()


func despawn_enemy():
 enemy_info_bar.disappear(true)
 %EnemyIntentContainer.clear_intents(true)
 enemy_marker.remove_child(enemy)
 enemy.queue_free()
 enemy = null
 Game.enemy = null


func get_save_metadata():
 var run_metadata = {
  character = player.id, 
  difficulty = Game.difficulty, 
  seeded = Game.is_seeded, 
  seed = rng.game.get_seed_hex(), 
  debug_run = Game.debug_run, 
  act = act, 
  last_played = Time.get_unix_time_from_system(), 
  turn_taken = player_has_taken_turn, 
  content_mods = ModLoader.get_active_mod_ids(true), 
  mods = ModLoader.get_active_mod_ids(), 
 }

 if Game.active_daily and not Game.debug_run:
  run_metadata.daily = Game.active_daily.date
  if Bridge.version_has_leaderboards():
   var forfeit_entry: = generate_leaderboard_entry(false, true)
   run_metadata.forfeit_entry = forfeit_entry.get_save_data()


 return run_metadata


func get_save_data():
 var save = {
  board = tile_board.get_save_data(), 
  run_stats = run_stats.get_save_data(), 
  spell_select = spell_select.get_save_data(), 
  act_events = act_events, 
  kills = kills, 
  spell_pool = spell_pool, 
  achievement_data = AchievementManager.get_save_data(), 
  rng = RNG.get_rng_group_save(rng), 
  background = background.get_save_data(), 
  forfeit = forfeit_quitting, 
  persistent_data = persistent_data, 
  showing_act_end_summary = showing_act_end_summary, 
  showing_floor_end_continue = showing_floor_end_continue, 
 }

 save.spells = spell_container.get_save_data()

 save.player = player.get_save_data()

 if enemy != null:
  save["enemy"] = {
   save = enemy.get_save_data(), 
   id = enemy.id, 
  }

 for mod in ModLoader.get_active_mods():
  var mod_run_save_data = mod.get_run_save_data()
  if mod_run_save_data.is_empty():
   if mod.mod_data.id in mod_save_data:
    mod_save_data.erase(mod.mod_data.id)
  else:
   mod_save_data[mod.mod_data.id] = mod_run_save_data

 save.mod_data = mod_save_data

 return save


func load_save_data(run_save):
 var run_metadata = run_save.metadata
 var save = run_save.data

 if enemy:
  despawn_enemy()

 if player:
  despawn_player()

 if "mod_data" in save:
  mod_save_data = save.mod_data
  for mod in ModLoader.get_active_mods():
   if mod.mod_data.id in "mod_data":
    mod.load_run_save_data(save.mod_data[mod.mod_data.id])

 RNG.load_rng_group_save(rng, save.rng)

 spell_pool = save.spell_pool
 act = run_metadata.get("act", save.get("act", 0))
 act_events = save.act_events
 kills = save.kills
 forfeit_continuing = save.forfeit
 persistent_data = save.get("persistent_data", {})
 StringManager.set_data_source("persistent_data", persistent_data)

 player_has_taken_turn = run_metadata.get("turn_taken", false)

 is_battle = "enemy" in save

 background.set_background_for_act(act)
 background.initialize_layers()
 background.load_save_data(save.background)

 if run_metadata.get("debug_run", false):
  Game.debug_run = true

 if "daily" in run_metadata:
  Game.active_daily = DailyManager.get_daily_data(run_metadata.daily)
 else:
  Game.active_daily = null

 Game.is_seeded = run_metadata.seeded
 Game.difficulty = run_metadata.difficulty
 Game.update_balance_vars()

 AchievementManager.load_save_data(save.achievement_data)
 run_stats.load_save_data(save.run_stats)

 spawn_player(run_metadata.character)
 player.load_save_data(save.player)

 player.show_health(true)

 spell_container.load_save_data(save.spells)

 tile_board.load_save_data(save.board)

 if "enemy" in save:
  spawn_enemy(save.enemy.id)
  enemy.load_save_data(save.enemy.save)
  enemy.post_ready()
  enemy.show_health(true)
  enemy.update_intents()
  enemy.play_battle_music(true)
  set_battle_rich_presence()

  if word_builder.slot_multipliers.size() != 0:
   word_builder.word_holder.show_slots(true)

 spell_select.load_save_data(save.spell_select)
 if "spells" in save.spell_select:
  save.spell_select.select_completed = false
  game_menu_controller.set_menu(spell_select, true)

 if save.get("showing_act_end_summary", false):
  show_act_end_summary(true)
 elif save.get("showing_floor_end_continue", false):
  show_floor_end_continue(true)

 elif "enemy" not in save and "spells" not in save.spell_select:
  change_floor()

 game_state_updated.emit()


func save_run():

 var save: = SaveManager.get_save()
 if Game.active_daily and save.can_play_daily(Game.active_daily.date):
  save.set_daily_played(Game.active_daily.date)

 save.store_file()

 if run_is_finished or (tutorial.active and tutorial.prevent_saving):
  return


 if Game.active_daily:
  save.save_daily(get_save_metadata(), get_save_data())
 else:
  save.save_run(get_save_metadata(), get_save_data())


func save_and_exit():
 if not Game.exiting_to_menu:
  AudioManager.fade_music()
  Game.exiting_to_menu = true
  Game.stop_turn_timers.emit()
  run_stats.stop_timers()
  save_run()
  screen_wipe.wipe_in()
  await screen_wipe.screen_covered
  Game.return_to_menu()


func enable_menu_wall() -> void :
 if menu_wall.mouse_filter == Control.MOUSE_FILTER_STOP:
  return

 menu_wall.mouse_filter = Control.MOUSE_FILTER_STOP
 var wall_tween: = create_tween()
 wall_tween.tween_property(menu_wall, "modulate", Color(0.0, 0.0, 0.0, 100.0 / 255.0), 0.16)


func disable_menu_wall() -> void :
 if menu_wall.mouse_filter == Control.MOUSE_FILTER_IGNORE:
  return

 menu_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var wall_tween: = create_tween()
 wall_tween.tween_property(menu_wall, "modulate", Color(0.0, 0.0, 0.0, 0.0), 0.16)


func check_menu_wall() -> void :
 if %PauseMenu.is_active_or_opening():
  enable_menu_wall()
 else:
  disable_menu_wall()


func debug_play_nobody_pattern() -> void :
 var carpet_layer: GameBGLayer
 for layer in background.get_children():
  if layer is GameBGLayer:
   if "carpet" in layer.layer_data.resource_path:
    carpet_layer = layer

 carpet_layer.deadzone = 0
 carpet_layer.layer_data.randomize_start = false
 background.play_pattern("nobody_office")
 carpet_layer.layer_data.randomize_start = true
 carpet_layer.deadzone = 32


func using_dialogue_cutscene_controls() -> bool:
 if tutorial.active and tutorial.can_advance():
  return true
 elif enemy != null and is_instance_valid(enemy) and enemy.is_playing_cutscene:
  return true

 return false


func _unhandled_input(event):
 if get_viewport().gui_get_focus_owner() is LineEdit or not get_window().has_focus():
  return

 if menu_controller.is_active():
  if event.is_action_pressed("menu_back"):
   toggle_pause()
 else:
  if event.is_action_pressed("pause"):
   toggle_pause()

 if not is_paused():
  if event.is_action_pressed("advance_cutscene") and Input.is_action_just_pressed("advance_cutscene"):
   if tutorial.active:
    tutorial.try_advance()
   elif enemy != null and is_instance_valid(enemy) and enemy.is_playing_cutscene:
    enemy.try_advance_cutscene()

 if not Bridge.is_debug_build():
  return

 if event.is_action_pressed("debug_charge_spells"):
  for spell in player.get_spells():
   spell.add_charge(99)

 elif event.is_action_pressed("debug_discharge_spells"):
  for spell in player.get_spells():
   spell.remove_charge(99)

 elif event.is_action_pressed("debug_save"):


  debug_save = var_to_bytes(get_save_data())

 elif event.is_action_pressed("debug_load") and debug_save != null:
  load_save_data(bytes_to_var(debug_save))

 elif event.is_action_pressed("debug_screenshake"):
  Game.screenshake(10, 0.5)

 elif event.is_action_pressed("debug_next_enemy"):
  force_skip_transition = true
  if is_player_turn:
   end_battle()
  elif spell_select.active:
   spell_select._on_skip_button_pressed()

 elif event.is_action_pressed("debug_kill_enemy"):
  if is_player_turn:
   player.deal_damage(enemy, 999)
   if enemy != null and enemy.is_flinching:
    await enemy.stopped_flinching
   end_player_turn()

 elif event.is_action_pressed("debug_explode"):
  if player.health != 1:
   player.hurt(player.health - 1)
  else:
   Game.screenshake(10, 2)
   player.hurt(999)


func _exit_tree() -> void :
 StringManager.erase_data_source("persistent_data")
 StringManager.erase_data_source("run")
 Game.main_scene_unloaded.emit()
 Game.release_node_handles()


func _on_pause_button_pressed():
 toggle_pause()


func _on_resume_button_pressed() -> void :
 toggle_pause()


func _on_quit_button_pressed() -> void :
 if player.id == Globals.CHARACTERS.ADDICT and is_player_turn:
  forfeit_quitting = true
  force_end_player_turn(true, false)
 else:
  save_and_exit()


func _on_pause_menu_start_appearing() -> void :
 AudioManager.effects.pause.set_enabled(true)


func _on_pause_menu_start_disappearing() -> void :
 AudioManager.effects.pause.set_enabled(false)


func _on_quit_button_start_appearing() -> void :
 if Game.active_daily:
  DailyManager.check_daily()

 var quit_button: MainMenuButton = %QuitButton
 if Game.active_daily and Game.active_daily.date != DailyManager.current_date:
  quit_button.set_info_text(StringManager.get_string("menu/pause/forfeit_run"))
  quit_button.enabled_theme = "MenuTicketBottomForfeit"
 elif player.id == Globals.CHARACTERS.ADDICT and is_player_turn:
  quit_button.set_info_text(StringManager.get_string("menu/pause/forfeit_turn"))
  quit_button.enabled_theme = "MenuTicketBottomForfeit"
 else:
  %QuitButton.set_info_text()
  quit_button.enabled_theme = "MenuTicketBottom"

 quit_button.update_theme()
