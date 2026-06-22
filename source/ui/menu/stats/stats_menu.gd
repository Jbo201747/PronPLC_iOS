extends MenuPanel

var spell_entry_scene: PackedScene = preload("res://source/ui/menu/stats/spell_stats_entry.tscn")

var base_spell_order: Array[String] = []
var spell_entries: Array[SpellStatsEntry] = []

@onready var sectioned_panel: SectionedPanel = %SectionedPanel

@onready var stats_label: RichTextLabel = %StatsLabel

@onready var spell_stats_container: VBoxContainer = %SpellStats

@onready var tab_controller: TabController = %TabController


func _ready() -> void :
 super._ready()

 for id in Globals.SPELLS.values():
  if id in Globals.UNTRACKED_SPELLS:
   continue

  base_spell_order.append(id)

  var instance: SpellStatsEntry = spell_entry_scene.instantiate()
  spell_stats_container.add_child(instance)
  instance.set_spell(id)
  spell_entries.append(instance)


func sort_spell_entries(entry_a: SpellStatsEntry, entry_b: SpellStatsEntry) -> bool:
 if entry_a.taken != entry_b.taken:
  return entry_a.taken > entry_b.taken
 elif entry_a.used != entry_b.used:
  return entry_a.used > entry_b.used
 else:
  return base_spell_order.find(entry_a.spell.id) < base_spell_order.find(entry_b.spell.id)


func update_spell_stats() -> void :
 for spell_entry in spell_entries:
  spell_entry.update_stats()

 spell_entries.sort_custom(sort_spell_entries)
 for i in spell_entries.size():
  var spell_entry: = spell_entries[i]
  spell_stats_container.move_child(spell_entry, i)


func _on_start_appearing() -> void :
 tab_controller.set_active_tab(tab_controller.tabs[0], false)


func update_stats_label() -> void :
 var save: = SaveManager.get_save()

 var favorite_word_times_used: int = 0
 var longest_favorite_word: String = ""
 var longest_favorite_word_length: int = -1
 var longest_word: String = ""
 var longest_word_length: int = 0
 for word: String in save.word_stats:
  var word_length = len(word)
  if word_length > longest_word_length:
   longest_word_length = word_length
   longest_word = word

  var word_times_used: int = save.word_stats[word]
  if word_times_used > favorite_word_times_used:
   longest_favorite_word = word
   longest_favorite_word_length = word_length
   favorite_word_times_used = word_times_used
  elif word_times_used == favorite_word_times_used and word_length > longest_favorite_word_length:
   longest_favorite_word = word
   longest_favorite_word_length = word_length

 var combined_difficulty_stats = Util.get_deep_accumulated(save.stats.difficulty, ["*"], {wins = 0, losses = 0})
 var red_clearance_stats: = save.get_difficulty_stats(9, false)

 var favorite_word: String = ""
 if longest_favorite_word != "":
  favorite_word = longest_favorite_word
 else:
  favorite_word = StringManager.get_string("menu/stats/not_applicable")

 var fastest_win: String = ""
 if save.stats.fastest_win != -1:
  fastest_win = StringManager.format_time(save.stats.fastest_win)
 else:
  fastest_win = StringManager.get_string("menu/stats/not_applicable")

 var context: Dictionary = {
  wins = combined_difficulty_stats.wins, 
  losses = combined_difficulty_stats.losses, 
  favorite_word = favorite_word, 
  longest_word = longest_word, 
  vocabulary_size = save.word_stats.size(), 
  win_streak = save.stats.streak, 
  best_win_streak = save.stats.best_streak, 
  max_difficulty_streak = red_clearance_stats.streak, 
  best_max_difficulty_streak = red_clearance_stats.best_streak, 
  deliberation_time = StringManager.format_time(save.stats.total_deliberation_time), 
  fastest_win = fastest_win, 
 }

 var hazel_clearance_stats: = save.get_difficulty_stats(10, false)
 if hazel_clearance_stats.wins > 0:
  context.hazel_streak = hazel_clearance_stats.streak
  context.best_hazel_streak = hazel_clearance_stats.best_streak

 stats_label.text = StringManager.get_string("menu/stats/global_stats", context)


func get_focus_controls() -> Array[Control]:
 return [sectioned_panel.scroll]


func _on_tab_controller_tab_changed(new_tab: TabButton) -> void :
 if new_tab.string_key == "menu/stats/general":
  update_stats_label()
 else:
  update_spell_stats()

 sectioned_panel.update_panels()
