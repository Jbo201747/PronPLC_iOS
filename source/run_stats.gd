class_name RunStats extends RefCounted



var encounter_history = []
var spell_usages = {}
var turns_taken = 0
var is_tracking_encounter = false

var deliberation_timer: = GameTimer.new()
var play_timer: = GameTimer.new(false)


func _init() -> void :
 deliberation_timer.stopped.connect(_on_deliberation_timer_stopped)
 play_timer.stopped.connect(_on_play_timer_stopped)


func start_tracking_encounter(enemy_name, act, initial_hp):
 encounter_history.append({
  act = act, 
  enemy_name = enemy_name, 
  initial_hp = initial_hp, 
  final_hp = -1, 
  time_spent = 0, 
  words = [], 
  damage = [], 
 })
 is_tracking_encounter = true


func get_current_encounter():
 if is_tracking_encounter:
  return encounter_history.back()
 else:
  return null


func stop_tracking_encounter(final_hp):
 if not is_tracking_encounter:
  return

 var current_encounter = get_current_encounter()
 current_encounter.final_hp = final_hp
 deliberation_timer.stop()
 is_tracking_encounter = false


func _on_deliberation_timer_stopped(elapsed_ms: int) -> void :
 var current_encounter = get_current_encounter()
 if current_encounter != null:
  current_encounter.time_spent += elapsed_ms
  AchievementManager.deliberation_tracked(elapsed_ms)


func _on_play_timer_stopped(elapsed_ms: int) -> void :
 AchievementManager.play_time_tracked(elapsed_ms)


func stop_timers() -> void :
 deliberation_timer.stop()
 play_timer.stop()


func get_current_encounter_time():
 var current_encounter = get_current_encounter()
 if current_encounter == null:
  return -1

 var encounter_time = current_encounter.time_spent
 if deliberation_timer.is_active:
  encounter_time += deliberation_timer.get_elapsed_time()

 return encounter_time


func submitted_words(words: WordList, damage_dealt: int) -> void :
 var current_encounter = get_current_encounter()
 if current_encounter != null:
  current_encounter.words.append_array(words.words)
  current_encounter.damage.append(damage_dealt)


func track_spell_used(id):
 if id not in spell_usages:
  spell_usages[id] = 1
 else:
  spell_usages[id] += 1


func track_turn():
 turns_taken += 1


func get_encounters(act = -1):
 var encounters = []
 for encounter in encounter_history:
  if act != -1 and act != encounter.act:
   continue

  encounters.append(encounter)

 return encounters


func get_words(act = -1) -> Array[String]:
 var words: Array[String] = []
 for encounter in get_encounters(act):
  words.append_array(encounter.words)

 return words


func get_longest_words(act = -1, count = 2147483647) -> Array[String]:
 var words = get_words(act)
 words.sort_custom( func(a, b): return len(a) > len(b))
 return words.slice(0, count)


func get_max_damage(act = -1):
 var max_damage = - INF
 for encounter in get_encounters(act):
  if encounter.damage.size() > 0:
   max_damage = max(max_damage, encounter.damage.max())

 return max(max_damage, 0)


func sort_encounter_length(encounter_a, encounter_b, lowest = true):
 if lowest:
  return encounter_a.time_spent < encounter_b.time_spent
 else:
  return encounter_a.time_spent > encounter_b.time_spent


func get_sorted_encounters(act = -1, count = 1, shortest: = false):
 var encounters = get_encounters(act)
 encounters.sort_custom(sort_encounter_length.bind(shortest))
 if count == 1:
  return encounters[0]

 return encounters.slice(0, count)


func get_longest_encounter(act = -1, count = 1):
 return get_sorted_encounters(act, count, false)


func get_shortest_encounter(act = -1, count = 1):
 return get_sorted_encounters(act, count, true)


func get_total_deliberation_time(act = -1):
 var time_spent: = 0
 if deliberation_timer.is_active:
  time_spent += deliberation_timer.get_elapsed_time()

 for encounter in get_encounters(act):
  time_spent += encounter.time_spent

 return time_spent


func get_save_data():
 return {
  encounter_history = encounter_history, 
  is_tracking_encounter = is_tracking_encounter, 
  spell_usages = spell_usages, 
  turns_taken = turns_taken, 
 }


func load_save_data(save):
 encounter_history = save.encounter_history
 is_tracking_encounter = save.is_tracking_encounter
 spell_usages = save.spell_usages
 turns_taken = save.turns_taken
