extends Window


const TileType = Globals.TileType
const TileStatus = Globals.TileStatus

var SPELLS = Globals.SPELLS.values()

var COMMANDS: Array[Command] = [
 Command.new(
  "help", 
  help_command, 
  "provides info about commands", 
  [Argument.new("command", [], true)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "enemy", 
  enemy_command, 
  "spawns the enemy", 
  [Argument.new("name", Enemies.list())]
 ), 
 Command.new(
  "enemy_trans", 
  enemy_trans_command, 
  "spawns the enemy and plays the usual scrolling transition", 
  [Argument.new("name", Enemies.list())]
 ), 
 Command.new(
  "spell", 
  spell_command, 
  "grants the spell", 
  [Argument.new("name", SPELLS, true), Argument.new("curse", Globals.SPELL_CURSES.values(), true)]
 ), 
 Command.new(
  "charge", 
  charge_command, 
  "charges all spells by amount, or fully if not specified", 
  [Argument.new("amount", [], true, TYPE_INT)]
 ), 
 Command.new(
  "status", 
  status_command, 
  "set a status to be painted freely with right click", 
  [Argument.new("name", Globals.TileStatus.values(), true)]
 ), 
 Command.new(
  "type", 
  type_command, 
  "set right click to swap the type of tiles", 
  [], 
 ), 
 Command.new(
  "curse", 
  curse_command, 
  "applies the curse to the rightmost spell or topmost in spell select", 
  [Argument.new("name", Globals.SPELL_CURSES.values())]
 ), 
 Command.new(
  "select", 
  spell_select_command, 
  "triggers a spell select, optionally containing a specific spell", 
  [Argument.new("spell", SPELLS, true), Argument.new("curse", Globals.SPELL_CURSES.values() + [""], true), Argument.new("spell2", SPELLS, true), Argument.new("curse2", Globals.SPELL_CURSES.values() + [""], true)]
 ), 
 Command.new(
  "build", 
  build_command, 
  "gives a spell from each spell category"
 ), 
 Command.new(
  "lock", 
  lock_command, 
  "locks the tile board for a number of turns", 
  [Argument.new("turns", [], true, TYPE_INT)]
 ), 
 Command.new(
  "crit", 
  crit_command, 
  "spells a word on the board with crit tiles, or converts all tiles to crit", 
  [Argument.new("word", [], true)], 
  Command.Scenario.GAME, 
  true, 
 ), 
 Command.new(
  "place_word", 
  place_word_command, 
  "spell a word on the board", 
  [Argument.new("word", [], true)], 
  Command.Scenario.GAME, 
  true, 
 ), 
 Command.new(
  "paint", 
  paint_command, 
  "apply many statuses"
 ), 
 Command.new(
  "summary", 
  summary_command, 
  "shows the end of run summary", 
  [Argument.new("act", [], true, TYPE_INT)], 
  Command.Scenario.GAME, 
 ), 
 Command.new(
  "leaderboard", 
  leaderboard_command, 
  "shows the leaderboard for today's daily"
 ), 
 Command.new(
  "volume", 
  volume_command, 
  "changes the volume of the current track, or prints the current volume", 
  [Argument.new("new_volume", [], true, TYPE_FLOAT)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "reset_song", 
  reset_song_command, 
  "replays the current song from the start", 
  [Argument.new("loop", ["loop"], true, TYPE_STRING)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "similar", 
  similar_command, 
  "rerolls all tiles to similar faces"
 ), 
 Command.new(
  "reset_steam", 
  reset_steam_command, 
  "resets all steam stats and achievements", 
  [], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "weight", 
  weight_command, 
  "greatly increases the weight of a spell", 
  [Argument.new("spell", SPELLS)]
 ), 
 Command.new(
  "difficulty", 
  difficulty_command, 
  "changes the game difficulty and restarts the current fight", 
  [Argument.new("number", [], false, TYPE_INT)]
 ), 
 Command.new(
  "board", 
  board_command, 
  "resizes the board", 
  [
   Argument.new("rows", [], true, TYPE_INT), 
   Argument.new("columns", [], true, TYPE_INT), 
   Argument.new("preview_rows", [], true, TYPE_INT), 
   Argument.new("restock_depth", [], true, TYPE_INT)
  ]
 ), 
 Command.new(
  "shake", 
  shake_command, 
  "shakes the screen", 
  [
   Argument.new("intensity", [], false, TYPE_FLOAT), 
   Argument.new("duration", [], false, TYPE_FLOAT)
  ], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "vibrate", 
  vibrate_command, 
  "vibrates the controller", 
  [
   Argument.new("weak_magnitude", [], false, TYPE_FLOAT), 
   Argument.new("strong_magnitude", [], true, TYPE_FLOAT), 
   Argument.new("duration", [], true, TYPE_FLOAT)
  ], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "is_word", 
  is_word_command, 
  "checks if word is in the dictionary", 
  [Argument.new("word")], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "queue_debug", 
  queue_debug_command, 
  "toggles queue debugging tools"
 ), 
 Command.new(
  "seed", 
  seed_command, 
  "print current run seed", 
 ), 
 Command.new(
  "hide_enemy", 
  hide_enemy_command, 
  "hide the enemy for yummy screenshots"
 ), 
 Command.new(
  "hide_board", 
  hide_board_command, 
  "hide the board for yummy screenshots"
 ), 
 Command.new(
  "popup_achievement", 
  popup_achievement_command, 
  "display an achievement popup", 
  [Argument.new("achievement", Globals.ACHIEVEMENTS.values() + Globals.SPELL_ACHIEVEMENTS), Argument.new("queue", ["true"], true, TYPE_STRING)]
 ), 
 Command.new(
  "set_achievement", 
  set_achievement_command, 
  "force set an achievement", 
  [Argument.new("achievement", Globals.ACHIEVEMENTS.values() + Globals.SPELL_ACHIEVEMENTS), Argument.new("count", [], true, TYPE_INT)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "poof", 
  poof_command, 
  "create a tile colored poof on all tiles", 
  [Argument.new("delay", [], true, TYPE_FLOAT)]
 ), 
 Command.new(
  "global_stats", 
  global_stats_command, 
  "display steam global stats", 
  [Argument.new("exclude_self", ["true"], true, TYPE_STRING)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "slash", 
  slash_command, 
  "slash all tiles"
 ), 
 Command.new(
  "queue", 
  queue_command, 
  "modify the tile queue", 
  [Argument.new("letters", [], false, TYPE_STRING)], 
 ), 
 Command.new(
  ["take_damage", "suffer"], 
  suffer_command, 
  "take damage", 
  [Argument.new("amount", [], false, TYPE_INT)]
 ), 
 Command.new(
  ["deal_damage", "inflict"], 
  inflict_command, 
  "hurt enemy", 
  [Argument.new("amount", [], false, TYPE_INT)]
 ), 
 Command.new(
  ["defend", "defense", "turtle"], 
  turtle_command, 
  "defend for amount", 
  [Argument.new("amount", [], true, TYPE_INT)]
 ), 
 Command.new(
  ["music", "play_song"], 
  play_song_command, 
  "play specific music track", 
  [Argument.new("song", get_song_list(), true, TYPE_STRING), Argument.new("play_loop", ["true", "false"], true, TYPE_STRING), Argument.new("volume", [], true, TYPE_FLOAT)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "numberize", 
  numberize_command, 
  "convert all tiles to numbers", 
 ), 
 Command.new(
  "daily", 
  daily_command, 
  "play the daily run in debug mode", 
  [], 
  Command.Scenario.MENU, 
 ), 
 Command.new(
  "cutscene", 
  cutscene_command, 
  "play a cutscene", 
  [Argument.new("cutscene", get_cutscene_list())], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "flinch_lethal", 
  flinch_lethal_command, 
  "play the enemy's death animation", 
  [], 
  Command.Scenario.GAME, 
 ), 
 Command.new(
  "blood_explode", 
  blood_explode_command, 
  "cause the enemy to blood explode", 
 ), 
 Command.new(
  "sound", 
  sound_command, 
  "play a sound", 
  [Argument.new("sound", Sounds.SOUND_CONSTANTS.keys()), Argument.new("volume", [], true, TYPE_FLOAT), Argument.new("pitch", [], true, TYPE_FLOAT)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "force_reroll", 
  force_reroll_command, 
  "guarantee a certain word to appear next reroll", 
  [Argument.new("word")], 
 ), 
 Command.new(
  "tutorial", 
  tutorial_command, 
  "set save file to play tutorial again", 
  [], 
  Command.Scenario.MENU, 
 ), 
 Command.new(
  "save_board", 
  save_board_command, 
  "save board state to file", 
 ), 
 Command.new(
  "load_board", 
  load_board_command, 
  "load board state from file", 
  [FileArgument.new("file", "user://debug/board_states", ".dat")], 
 ), 
 Command.new(
  "timescale", 
  timescale_command, 
  "set engine time scale", 
  [Argument.new("timescale", [], false, TYPE_FLOAT)], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "macro", 
  macro_command, 
  "set a command to run when F4 is pressed", 
  [Argument.new("command", [], true)], 
  Command.Scenario.ANY, 
  true, 
 ), 
 Command.new(
  "score", 
  score_command, 
  "calculate leaderboard score for given parameters", 
  [Argument.new("victory", [], false, TYPE_INT), Argument.new("kills", [], false, TYPE_INT), Argument.new("turns", [], false, TYPE_INT), Argument.new("damage", [], false, TYPE_INT), Argument.new("time", [], false, TYPE_INT)], 
  Command.Scenario.ANY
 ), 
 Command.new(
  "fuck_tutorial", 
  fuck_tutorial_command, 
  "kill destroy the tutorial", 
  [], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "nobody", 
  play_nobody_cutscene_command, 
  "play a nobody cutscene", 
  [Argument.new("cutscene", get_nobody_cutscene_list())], 
  Command.Scenario.GAME, 
 ), 
 Command.new(
  "print_unlocks", 
  print_unlocks_command, 
  "toggle printing achievement ids when unlock condition is met", 
  [], 
 ), 
 Command.new(
  "save_leaderboards", 
  save_leaderboards_command, 
  "save all leaderboard entries to file", 
  [], 
  Command.Scenario.ANY, 
 ), 
 Command.new(
  "load_leaderboards", 
  load_leaderboards_command, 
  "load leaderboards from file for viewing", 
  [FileArgument.new("file", "user://debug/leaderboard_dumps", ".dat")], 
  Command.Scenario.ANY, 
 )
]

var command_map: Dictionary[String, Command] = {}

var autofill_text = ""
var command_history: Array[String] = []
var command_history_index: int = 0

var queue_debug_history = []
var queue_debug_history_index = 0
var queue_debug_vowels_consonants = ""
var queue_debug_last_census = ""

var saved_macro: String = ""

var queued_commands: Array[String] = []

var main:
 get():
  return Game.main

var tile_board:
 get():
  return Game.tile_board

@onready var queue_debug = $VBoxContainer / QueueDebug
@onready var output = $VBoxContainer / Output
@onready var input = $VBoxContainer / Input
@onready var input_predict = $VBoxContainer / Input / InputPredict


func _init() -> void :
 Bridge.dev_console = self


func _ready():
 initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
 position = DisplayServer.screen_get_position(current_screen) + Vector2i(50, 50)

 var command_names: Array = []
 for command in COMMANDS:
  for command_name in command.commands:
   command_names.append(command_name)
   command_map[command_name] = command

 command_map["help"].argument_configs[0].autocomplete_source = command_names



 Game.main_scene_loaded.connect(_main_scene_loaded)


func _main_scene_loaded() -> void :
 if Bridge.is_debug_build():
  tile_board.queue.filling_queue.connect(_queue_debug_filling_queue)
  tile_board.queue.queue_updated.connect(_queue_debug_queue_updated)

  for command in queued_commands:
   run_command(command)


func _notification(what: int) -> void :
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  close()


func set_input(new_text):
 input.text = new_text
 _on_input_text_changed(new_text)

 await get_tree().process_frame
 input.caret_column = new_text.length()


func make_prediction(text, candidates):
 for candidate in candidates:
  if text.length() < candidate.length() and candidate.begins_with(text):
   return candidate

 return ""


func _input(event):
 if event is InputEventKey and event.pressed:
  if Input.is_key_pressed(KEY_UP):
   if command_history.is_empty():
    return

   if command_history_index > command_history.size():
    command_history_index = command_history.size()

   command_history_index = maxi(command_history_index - 1, 0)
   set_input(command_history[command_history_index])
  elif Input.is_key_pressed(KEY_DOWN):
   if command_history.is_empty():
    return

   command_history_index = maxi(mini(command_history_index + 1, command_history.size()), 0)
   if command_history_index == command_history.size():
    set_input("")
   else:
    set_input(command_history[command_history_index])

  elif Input.is_key_pressed(KEY_TAB):
   if autofill_text.is_empty():
    return
   set_input(autofill_text)

  elif Input.is_key_pressed(KEY_QUOTELEFT):
   close()

  elif input.text == "" and queue_debug.visible:
   var add_index = 0
   if Input.is_key_pressed(KEY_LEFT):
    add_index = -1
   elif Input.is_key_pressed(KEY_RIGHT):
    add_index = 1

   if add_index != 0 and queue_debug_history.size() > 0:
    queue_debug_history_index = (queue_debug_history_index + add_index) % queue_debug_history.size()
    queue_debug.text = queue_debug_history[queue_debug_history_index]


func close() -> void :
 set_input("")
 hide()


func output_text(text, error = false):
 if error:
  text = "[color=orangered]" + text + "[/color]"

 output.append_text(text)


func _on_input_text_submitted(new_text):
 set_input("")

 if new_text in command_history:
  command_history.erase(new_text)

 command_history.append(new_text)
 command_history_index = command_history.size()
 output.append_text("[color=#ffffff88]" + new_text + "[/color]" + "\n")

 run_command(new_text)


func run_command(command_text: String) -> void :
 var words = command_text.split(" ")

 var command_name = words[0]
 var arguments = words.slice(1)

 if command_name not in command_map:
  output_text(command_name + " is not a valid command", true)
  return

 var command = command_map[command_name]
 if not command.is_usable():
  output_text(command_name + " is not usable right now", true)
  return

 var execution_args = command.process_arguments(arguments)
 if execution_args is String:
  output_text(execution_args, true)
 else:
  command.execute(execution_args)


func _on_input_text_changed(new_text: String):
 var words: = new_text.split(" ")


 var prediction = ""
 var autofill_array: = PackedStringArray()
 if words.size() == 1 and new_text != "":
  var usable_commands: Array = []
  for command_name in command_map:
   if command_map[command_name].is_usable():
    usable_commands.append(command_name)

  prediction = make_prediction(words[0], usable_commands)
 else:
  var command_name = words[0]
  if command_name in command_map:
   var command: = command_map[command_name]
   var argument_index = words.size() - 2
   if argument_index < command.argument_configs.size():
    var argument_config: = command.argument_configs[argument_index]
    argument_config.refresh_autocomplete()
    if argument_config.autocomplete_source.size() > 0:
     autofill_array = words.slice(0, argument_index + 1)
     prediction = make_prediction(words[argument_index + 1], argument_config.autocomplete_source)

 if prediction != "":
  autofill_array.append(prediction)
  autofill_text = " ".join(autofill_array)
  var predicted_text = "[color=#ffffff88]" + autofill_text.substr(new_text.length()) + "[/color]"
  var whitespace_text = "[color=#ffffff00]" + new_text + "[/color]"
  input_predict.text = whitespace_text + predicted_text
 else:
  input_predict.text = ""
  autofill_text = ""


func _on_visibility_changed():
 if visible and is_node_ready():
  input.grab_focus()


func enemy_command(enemy_id):
 main.force_skip_transition = true
 enemy_trans_command(enemy_id, true)


func enemy_trans_command(enemy_id, skip_transition: = false):
 var act_and_floor = Enemies.get_act_and_floor(enemy_id)

 main.act = act_and_floor.act
 Game.debug_spawn_enemy = enemy_id
 main.generate_act()
 main.act_events = [{}] + main.act_events
 main.background.set_background_for_act(main.act)
 main.background.initialize_layers()
 if enemy_id == Enemies.NOBODY and skip_transition:
  main.debug_play_nobody_pattern()
 else:
  main.background.play_pattern("loop")
 main.end_battle(true)


func spell_command(spell_id: = "", curse_id: = ""):
 if spell_id == "":
  spell_id = main.pick_random_spell()

 var spell: = Spell.create(spell_id)
 if curse_id != "":
  spell.set_curse(curse_id)

 spell._first_spawn()
 if main.player.has_max_spells():
  var spells = main.player.get_spells()
  main.spell_container.replace_spell(spells[-1], spell)
 else:
  main.spell_container.add_spell(spell)

 spell.add_charge(99)


func build_command():
 var added_spells = []
 for category in Globals.SPELL_CATEGORIES:
  var spell = ""
  while spell == "" or spell in added_spells:
   spell = Globals.SPELL_CATEGORIES[category].pick_random()

  spell_command(spell)


func charge_command(charge = 99):
 for spell in main.player.get_spells():
  spell.add_charge(charge)


func status_command(status_id = ""):
 if status_id == "":
  Game.debug_painting_status = null
  output.append_text("No longer painting statuses.\n")
 else:
  Game.debug_painting_status = status_id
  output.append_text("Now painting status \"" + status_id + "\"\n")


func type_command():
 if Game.debug_painting_status == null:
  Game.debug_painting_status = "type"
  output.append_text("Now swapping tile type.\n")
 else:
  Game.debug_painting_status = null
  output.append_text("No longer swapping tile type.\n")


func help_command(command_name = ""):
 var help_text = ""
 if command_name != "":
  help_text += command_map[command_name].get_help_string() + "\n"
 else:
  for command in COMMANDS:
   if command.command != "help":
    help_text += command.get_help_string() + "\n"

 output.append_text(help_text)


func paint_command():
 var target_tiles = {
  TileStatus.ACID: tile_board.get_tiles({columns = [0, 2], rows = [0]}), 
  TileStatus.COAL: tile_board.get_tiles({columns = [1, 3], rows = [0]}), 
  TileStatus.ASH: tile_board.get_tiles({columns = [0, 1], rows = [1]}), 
  TileStatus.POISON: tile_board.get_tiles({columns = [2, 3], rows = [1]}), 
  TileStatus.SPICY: tile_board.get_tiles({columns = [0, 1], rows = [2]}), 
  TileStatus.BLEED: tile_board.get_tiles({columns = [2, 3], rows = [2]}), 
  TileStatus.FROZEN: tile_board.get_tiles({rows = [3]}), 
 }

 for key in target_tiles:
  var status_id = key

  for tile in target_tiles[status_id]:
   tile.add_status(status_id)


func lock_command(num_turns = 1):
 tile_board.lock_restock(num_turns)


func place_word_on_board(word: String) -> Array[Tile]:
 var num_spaces: int = word.count(" ")
 var total_letters: int = len(word) - num_spaces

 var tiles = tile_board.get_tiles({sorted = true})
 var available_tiles: int = tiles.size() - num_spaces
 var letters_per_tile: float = maxf(1.0, float(total_letters) / float(available_tiles))

 var extra_letter_accumulator: float = 0.0

 var altered_tiles: Array[Tile] = []

 var words: PackedStringArray = word.split(" ")
 for i in words.size():
  var place_word: = words[i]
  var characters: = place_word.split()
  while not characters.is_empty():
   var letters: int = floori(letters_per_tile)
   extra_letter_accumulator += letters_per_tile - floorf(letters_per_tile)
   if extra_letter_accumulator >= 1.0 and letters < characters.size() and letters < 3:
    extra_letter_accumulator -= 1.0
    letters += 1

   letters = mini(mini(characters.size(), letters), 3)

   var face: = "".join(characters.slice(0, letters))
   var tile: Tile = tiles.pop_front()
   if tile != null:
    tile.remove_statuses([TileStatus.PERIOD, TileStatus.CAPITAL])
    tile.set_face(face)
    altered_tiles.append(tile)

   characters = characters.slice(letters)

  if i < words.size() - 1:
   var tile: Tile = tiles.pop_front()
   if tile != null:
    tile.apply_hole(false)
    altered_tiles.append(tile)

 return altered_tiles


func place_word_command(word: String, words: Array[String] = []):
 if words.size() > 0:
  place_word_on_board(word + " " + " ".join(words))
 else:
  place_word_on_board(word)


func crit_command(word = "", words: Array[String] = []):
 var altered_tiles: Array
 if word == "":
  altered_tiles = tile_board.get_tiles()
 elif words.size() > 0:
  altered_tiles = place_word_on_board(word + " " + " ".join(words))
 else:
  altered_tiles = place_word_on_board(word)

 for tile: Tile in altered_tiles:
  tile.add_status(TileStatus.CRIT)
  tile.set_type(TileType.DAMAGE)

  if word != "":
   Game.word_builder.try_add_tile(tile)


func spell_select_command(forced_spell_id = "", curse_id = "", spell_2 = "", curse_2 = ""):
 if spell_2 != "":
  main.spell_select.force_spell = [forced_spell_id, spell_2]
 elif forced_spell_id != "":
  main.spell_select.force_spell = forced_spell_id
 else:
  main.spell_select.force_spell = null

 main.spell_select.is_debug_select = true
 main.spell_select.generate_spells()
 if curse_id != "" or curse_2 != "":
  for spell: SpellSelectSpell in main.spell_select.get_spells():
   if spell.spell.id == forced_spell_id and curse_id != "":
    spell.spell.set_curse(curse_id)
   elif spell.spell.id == spell_2 and curse_2 != "":
    spell.spell.set_curse(curse_2)

   spell.spell_sprite._on_spell_charge_updated()
   spell.update()

 main.game_menu_controller.set_menu(main.spell_select)


func summary_command(act: int = -1):
 main.show_summary(act, true, act != -1)


func leaderboard_command():
 if not Bridge.version_has_leaderboards():
  output_text("Leaderboards are unavailable.", true)
  return

 main.summary_menu.show_leaderboard()


func volume_command(set_volume = -1.0):
 if set_volume == -1.0:
  var volume = 1
  if AudioManager.active_music and "VOLUME" in AudioManager.active_music:
   volume = AudioManager.active_music.VOLUME

  output.append_text("Default Track Volume: " + str(volume) + "\n")
 else:
  if AudioManager.active_music:
   AudioManager.music_player.volume_db = linear_to_db(set_volume)
  else:
   output.append_text("[color=orangered]Cannot change music volume without a song playing.[/color]\n")


func get_song_list() -> Array[String]:
 var list: Array[String] = []
 for key in Globals.MUSIC:
  list.append(key.to_lower())

 return list


func play_song_command(song: String = "", play_loop: = "", volume: float = -1.0):
 if song == "":
  reset_song_command()

 AudioManager.play_music(Globals.MUSIC[song.to_upper()], play_loop != "true", volume)


func reset_song_command(loop: String = ""):
 if AudioManager.active_music:
  AudioManager.play_music(AudioManager.active_music, loop != "loop")


func similar_command():
 for tile in tile_board.get_tiles({has_face = true}):
  tile.randomize_similar_face()


func reset_steam_command():
 Bridge.reset_steam_stats.emit()


func weight_command(spell_id):
 main.spell_pool[spell_id] = 10000.0


func curse_command(curse_id):
 if main.spell_select.active:
  var last_spell_select = main.spell_select.get_spells()[-1]
  last_spell_select.spell.set_curse(curse_id)
  last_spell_select.spell_sprite._on_spell_charge_updated()
  last_spell_select.update()
 else:
  var last_spell = Game.player.get_spells()[-1]
  last_spell.set_curse(curse_id)
  last_spell.spell_sprite._on_spell_charge_updated()


func difficulty_command(difficulty):
 if difficulty >= 0 and difficulty <= 10:
  Game.difficulty = difficulty
  Game.update_balance_vars()
  Game.difficulty_changed.emit()

  output.append_text("Changed difficulty to " + str(difficulty))

  return

 output.append_text("[color=orangered]Difficulty must be an integer from 0 - 10.[/color]\n")


func board_command(columns = 4, rows = 4, preview_rows = 1, restock_depth = null):
 tile_board.set_size(columns, rows, preview_rows, restock_depth)


func is_word_command(word):
 if WordUtility.dictionary.is_word(word):
  output.append_text(word + " is a valid word.\n")

  var flags: = PackedStringArray()
  for flag: String in WordDictionary.WordFlags:
   if WordUtility.dictionary.word_has_flag(word, WordDictionary.WordFlags[flag]):
    flags.append(flag.to_lower())

  if not flags.is_empty():
   output.append_text("Flags: " + " ".join(flags) + "\n")
 else:
  output.append_text(word + " is not a valid word.\n")


func shake_command(intensity, duration):
 Game.screenshake(intensity, duration)


func vibrate_command(weak: float, strong: float, duration: float) -> void :
 InputManager.vibrate(weak, strong, duration)


func get_queue_debug_queue_string():
 var highest_coord = 0
 for coord in tile_board.queue.queue:
  if coord.y > highest_coord:
   highest_coord = coord.y

 var queue_string = ""
 for y in range(highest_coord, -1, -1):
  for x in tile_board.queue.num_columns:
   var coord = Vector2i(x, y)
   if coord in tile_board.queue.queue:
    var queued_tile = tile_board.queue.get_at_coord(coord)
    queue_string += queued_tile.faces[0]
    if "forced_vowel" in queued_tile:
     queue_string += " (v)"
    elif "forced_consonant" in queued_tile:
     queue_string += " (c)"
    else:
     queue_string += "    "
   else:
    queue_string += "?    "

   if x != tile_board.queue.num_columns - 1:
    queue_string += " "

  queue_string += "\n"

 return queue_string


func get_queue_debug_census_string(census):
 if census == null:
  return queue_debug_last_census

 var census_string = ""
 var letter_column = 0
 var letter_weights = Letters.get_adjusted_letters(Letters.LETTERS, [], census)
 for letter in Letters.ALPHABET:
  var letter_string = letter + ": "
  if letter in census:
   letter_string += str(census[letter])
  else:
   letter_string += "0"

  letter_string += " " + ("%.2f" % letter_weights[letter])
  letter_column += 1
  if letter_column > 3:
   letter_string += "\n"
   letter_column = 0
  elif letter != "z":
   letter_string += " | "

  census_string += letter_string

 return census_string


func _queue_debug_filling_queue(census, needed_vowels, needed_consonants):
 if tile_board.queue.get_open_coords(tile_board.queue.target_coords).size() > 0:
  queue_debug_history = []
  queue_debug_vowels_consonants = "need vowel: " + str(needed_vowels) + ", need cons: " + str(needed_consonants)
  _queue_debug_queue_updated(census)



func _queue_debug_queue_updated(census):
 var debug_string = queue_debug_vowels_consonants + ", index: " + str(queue_debug_history.size()) + "\n"
 debug_string += get_queue_debug_queue_string() + get_queue_debug_census_string(census)
 queue_debug_history.append(debug_string)
 queue_debug.text = debug_string
 queue_debug_history_index = queue_debug_history.size() - 1


func queue_debug_command():
 if queue_debug.visible:
  queue_debug.visible = false
 else:
  queue_debug.visible = true


func seed_command():
 output.append_text("Seed is " + Game.main.rng.game.get_seed_hex())


func hide_enemy_command():
 main.enemy.visible = not main.enemy.visible
 main.enemy_info_bar.visible = not main.enemy_info_bar.visible
 main.enemy.intent_container.visible = not main.enemy.intent_container.visible


func hide_board_command():
 main.tile_board.visible = not main.tile_board.visible
 main.tile_container.visible = not main.tile_container.visible


func popup_achievement_command(achievement: String, queue: String = ""):
 if queue == "true":
  AchievementManager.queue_unlock_popup(achievement)
 else:
  AchievementManager.achievement_popup(achievement)


func set_achievement_command(achievement: String, count: int = 1):
 SaveManager.get_save().set_achievement_level(achievement, count)


func poof_command(delay: float = 0):
 for tile: Tile in tile_board.get_tiles():
  tile.add_poofcloud(tile.get_color())
  if delay != 0:
   await Game.timeout(delay)


func global_stats_command(exclude_self: = "") -> void :
 Bridge.request_global_stats.emit(exclude_self == "true")


func slash_command() -> void :
 for tile: Tile in tile_board.get_tiles():
  var first_face = tile.face
  var second_face = Letters.get_random_letter(null, Game.random, [first_face])
  tile.set_slashed([first_face, second_face])


func queue_command(change_to: String) -> void :
 var queued_tiles = tile_board.get_preview_tiles()
 for i in len(change_to):
  if i >= queued_tiles.size():
   break

  queued_tiles[i].faces = [change_to[i]]

 tile_board.update_previews()


func suffer_command(amount: int) -> void :
 Game.player.hurt(amount, Globals.DamageType.PIERCING)
 await Game.player.recompose()


func inflict_command(amount: int) -> void :
 Game.enemy.hurt(amount, Globals.DamageType.PIERCING)


func turtle_command(amount: int = 0) -> void :
 Game.player.defense = amount


func numberize_command() -> void :
 for tile in tile_board.get_tiles():
  if tile.is_single_letter(false):
   for numpad in Letters.NUMPAD_CHARACTERS:
    if tile.face in Letters.NUMPAD_CHARACTERS[numpad]:
     tile.set_face(numpad)
     break


func daily_command() -> void :
 Game.start_daily_run(true)


func get_cutscene_list() -> Array[String]:
 var cutscenes: Array[String] = []
 var cutscene_root: = StringManager.get_string_group("cutscenes")
 for group_name in cutscene_root.groups:
  var sub_group: = cutscene_root.groups[group_name]
  for sub_group_name in sub_group.groups:
   cutscenes.append(group_name + "/" + sub_group_name)

 return cutscenes


func cutscene_command(cutscene: String) -> void :
 AudioManager.fade_music()
 if Game.is_in_run():
  await Game.main.screen_wipe.wipe_in()
  Game.main.cutscene.play_cutscene(cutscene)
  await Game.main.cutscene.finished
  Game.main.screen_wipe.wipe_out()
 else:
  await Game.main_menu.screen_wipe.wipe_in()
  Game.main_menu.cutscene.play_cutscene(cutscene)
  await Game.main_menu.cutscene.finished
  Game.main_menu.screen_wipe.wipe_out()


func flinch_lethal_command() -> void :
 if not Game.is_in_run() or Game.main.enemy == null or not Game.main.is_battle:
  output.append_text("[color=orangered]Must be in combat with an enemy!.[/color]\n")
  return

 Game.main.enemy.clear_intent()
 await Game.main.enemy.animate_flinch_lethal()
 await Game.timeout(1.5)
 Game.main.enemy.anim_player.play_advance("RESET")
 if Game.main.enemy.idle_after_flinching:
  Game.main.enemy._play_idle()

 Game.main.enemy.sprite.visible = true
 Game.main.enemy.update_intents()


func blood_explode_command() -> void :
 if not Game.is_in_run() or Game.main.enemy == null or not Game.main.is_battle:
  output.append_text("[color=orangered]Must be in combat with an enemy!.[/color]\n")
  return

 Game.main.enemy.sprite.blood_explode()


func sound_command(sound_name: String, volume: float, pitch_scale: float) -> void :
 AudioManager.play_sound(Sounds.SOUND_CONSTANTS[sound_name], pitch_scale, volume)


func force_reroll_command(word: String) -> void :
 Game.debug_force_words.append(word)


func tutorial_command() -> void :
 SaveManager.get_save().set_viewed_tutorial(false)


func save_board_command() -> void :
 if not DirAccess.dir_exists_absolute("user://debug/board_states"):
  DirAccess.make_dir_recursive_absolute("user://debug/board_states")

 var time_filename = str(floori(Time.get_unix_time_from_system()))
 var file = FileAccess.open("user://debug/board_states/%s.dat" % time_filename, FileAccess.WRITE)
 if file:
  file.store_var(Game.tile_board.get_save_data())


func load_board_command(file_path: String) -> void :
 if not FileAccess.file_exists(file_path):
  output.append_text("[color=orangered]Could not find board file!.[/color]\n")

 var file = FileAccess.open(file_path, FileAccess.READ)
 if file:
  Game.tile_board.load_save_data(file.get_var())


func timescale_command(scale: float) -> void :
 Engine.time_scale = scale


func macro_command(command: String = "", arguments: Array[String] = []) -> void :
 if command == "":
  saved_macro = ""
  return

 arguments.insert(0, command)
 saved_macro = " ".join(arguments)


func run_macro() -> void :
 if saved_macro != "":
  run_command(saved_macro)


func score_command(victory: int, kills: int, turns: int, damage_taken: int, time_taken: int) -> void :
 var leaderboard_entry: = Bridge.LeaderboardEntry.create()
 leaderboard_entry.died = victory != 1
 leaderboard_entry.kills = kills
 leaderboard_entry.turns_taken = turns
 leaderboard_entry.damage_taken = damage_taken
 leaderboard_entry.time_taken = time_taken
 output_text("Leaderboard entry would have score of %s" % leaderboard_entry.get_score())


func fuck_tutorial_command() -> void :
 SaveManager.get_save().set_viewed_tutorial(true)
 SaveManager.get_save().store_file()
 if Game.is_in_run():
  if Game.main.tutorial.active:
   Game.main.tutorial.finish_tutorial()


func get_nobody_cutscene_list() -> Array[String]:
 var cutscenes: Array[String] = []
 var cutscene_root: = StringManager.get_string_group("nobody")
 for group_name in cutscene_root.groups:
  var sub_group: = cutscene_root.groups[group_name]
  for sub_group_name in sub_group.groups:
   cutscenes.append(sub_group.groups[sub_group_name].get_path_key())

 return cutscenes


func play_nobody_cutscene_command(id: String) -> void :
 if not Game.main.is_battle or Game.enemy == null or Game.enemy.id != Enemies.NOBODY:
  output_text("Must be in battle with Nobody!", true)

 await Game.tile_board.slide_out()
 await Game.enemy.play_cutscene(id)
 await Game.tile_board.slide_in()


func print_unlocks_command():
 Game.debug_print_achievement_unlocks = not Game.debug_print_achievement_unlocks
 if Game.debug_print_achievement_unlocks:
  output_text("Achievement ids will be printed when their unlock condition is met.")
 else:
  output_text("Achievement ids will no longer be printed when their unlock condition is met.")


func save_leaderboards_command() -> void :
 if not DirAccess.dir_exists_absolute("user://debug/leaderboard_dumps"):
  DirAccess.make_dir_recursive_absolute("user://debug/leaderboard_dumps")

 var time_filename = str(floori(Time.get_unix_time_from_system()))
 var file = FileAccess.open("user://debug/%s.dat" % time_filename, FileAccess.WRITE)
 if file:
  var leaderboard_data: Dictionary = {}
  for leaderboard_name in Bridge.leaderboards:
   var leaderboard: = Bridge.leaderboards[leaderboard_name]
   var entries: Array[Bridge.LeaderboardEntry] = []
   for entry in leaderboard.get_entries():
    entries.append(entry)

   if not entries.is_empty():
    leaderboard_data[leaderboard_name] = {entries = []}
    for entry in entries:
     leaderboard_data[leaderboard_name].entries.append(entry.get_save_data())

  print(leaderboard_data)
  file.store_var(leaderboard_data)


func load_leaderboards_command(file_path: String) -> void :
 if not FileAccess.file_exists(file_path):
  output.append_text("[color=orangered]Could not find leaderboard dump file![/color]\n")

 var file = FileAccess.open(file_path, FileAccess.READ)
 if file:
  var leaderboard_data: Dictionary = file.get_var()
  for leaderboard_name in leaderboard_data:
   var leaderboard: = Bridge.get_leaderboard(leaderboard_name)
   leaderboard.exists = true
   leaderboard.successfully_found_entries = true
   var entries: Array = leaderboard_data[leaderboard_name].entries
   var entries_by_score: Dictionary[int, Array] = {}
   for entry_data in entries:
    var entry: = Bridge.LeaderboardEntry.from_save(entry_data)
    var score: = entry.get_score()
    if score not in entries_by_score:
     entries_by_score[score] = []

    entries_by_score[score].append(entry)

   var sorted_scores = entries_by_score.keys()
   sorted_scores.sort()
   sorted_scores.reverse()

   var global_rank: int = 1
   for score in sorted_scores:
    var score_entries = entries_by_score[score]
    for entry: Bridge.LeaderboardEntry in score_entries:
     entry.global_rank = global_rank
     leaderboard.add_entry(entry)
     global_rank += 1



class Argument:
 var id: String
 var value_type: int
 var optional: bool
 var autocomplete_source: Array = []
 func _init(init_id: String, init_autocomplete_source: Array = [], init_optional: bool = false, init_value_type: int = TYPE_STRING):
  id = init_id
  value_type = init_value_type
  optional = init_optional
  autocomplete_source = init_autocomplete_source


 func process_arg(argument: String):
  if value_type == TYPE_STRING:
   if autocomplete_source.size() > 0 and argument not in autocomplete_source:
    return null
   else:
    return argument
  elif value_type == TYPE_FLOAT:
   if not argument.is_valid_float():
    return null
   else:
    return argument.to_float()
  elif value_type == TYPE_INT:
   if not argument.is_valid_int():
    return null
   else:
    return argument.to_int()


 func get_error_string(argument: String):
  if value_type == TYPE_STRING and argument not in autocomplete_source:
   return argument + " is not a valid " + id + ".\n"

  return argument + " is not a valid " + type_string(value_type) + ".\n"


 func get_hint_string() -> String:
  if optional:
   return "[%s]" % [id]
  else:
   return "<%s>" % [id]


 func refresh_autocomplete() -> void :
  pass


class FileArgument extends Argument:
 var folder: String = ""
 var extension: String = ""

 func _init(init_id: String, init_folder: String, init_extension: String = "", init_optional: bool = false):
  folder = init_folder
  extension = init_extension
  super._init(init_id, [], init_optional, TYPE_STRING)


 func process_arg(argument: String):
  if argument not in autocomplete_source:
   return null
  else:
   return "%s/%s" % [folder, argument]


 func refresh_autocomplete() -> void :
  autocomplete_source.clear()
  var paths: = Util.get_file_paths_recursive(folder, extension)
  for path in paths:
   autocomplete_source.append(path.replace(folder + "/", ""))


class Command:
 enum Scenario{
  ANY, 
  GAME, 
  MENU, 
 }

 var commands: Array[String] = []
 var function: Callable
 var description: String
 var argument_configs: Array[Argument]
 var usable_scenario: Scenario
 var varargs: bool = false

 func _init(init_command: Variant, init_function: Callable, init_description: String, init_argument_configs: Array[Argument] = [], init_usable_scenario: Scenario = Scenario.GAME, init_varargs: bool = false):
  if init_command is String:
   commands = [init_command]
  elif init_command is Array:
   commands.append_array(init_command)
  else:
   assert (false, "Command must be string or list of strings")

  function = init_function
  description = init_description
  argument_configs = init_argument_configs
  usable_scenario = init_usable_scenario
  varargs = init_varargs


 func get_help_string():
  var help_string = commands[0]
  for argument in argument_configs:
   help_string += " " + argument.get_hint_string()

  help_string += ": " + description
  return help_string


 func process_arguments(arguments: Array[String]):
  var error = ""
  var out_arguments = []
  for i in argument_configs.size():
   var argument_config = argument_configs[i]
   if i >= arguments.size():
    if not argument_config.optional:
     error += "Argument " + argument_config.get_hint_string() + " is non-optional.\n"
   else:
    var argument = arguments[i]
    var out_argument = argument_config.process_arg(argument)
    if out_argument == null:
     error += argument_config.get_error_string(argument)
    else:
     out_arguments.append(out_argument)

  if varargs and arguments.size() > argument_configs.size():
   out_arguments.append(arguments.slice(argument_configs.size()))

  if error != "":
   return error
  else:
   return out_arguments


 func execute(args):
  function.callv(args)


 func is_usable() -> bool:
  match usable_scenario:
   Scenario.GAME:
    return Game.is_in_run()
   Scenario.MENU:
    return not Game.is_in_run()
   _:
    return true
