@tool
class_name Summary extends SectionedPanel


const SUMMARY_LABEL = preload("res://source/ui/menu/summary/summary_label.tscn")
const FIGHT_SUMMARY = preload("res://source/ui/menu/summary/fight_summary.tscn")


var run_stats: RunStats


func generate_summary(act: int = -1, victory: bool = true) -> void :
 var context: = {
  act = act, 
  victory = victory, 
  time = StringManager.format_time(run_stats.get_total_deliberation_time(act)), 
 }

 %Title.text = StringManager.get_string("summary/title", context)
 %Time.text = StringManager.get_string("summary/time", context)

 %ActTimes.visible = act == -1
 if act == -1:
  var act_times: Array[String] = []
  for i in 3:
   var act_time = run_stats.get_total_deliberation_time(i)
   if act_time != 0:
    act_times.append(StringManager.format_time(act_time))
   else:
    break

  %ActTimes.text = StringManager.get_string("summary/act_times", {times = act_times})

 var longest_words: = run_stats.get_longest_words(act)
 var num_words: int = longest_words.size()
 var index: int = 0
 for word_label: Label in %LongestWordsBox.get_children():
  if index >= num_words:
   if index == 0:
    word_label.text = StringManager.get_string("summary/forgot")
   else:
    word_label.text = ""
  else:
   word_label.text = StringManager.get_string("summary/word", {word = longest_words[index]})

  index += 1

 %LongestFight.set_encounter("summary/longest_fight", run_stats.get_longest_encounter(act))
 %ShortestFight.set_encounter("summary/shortest_fight", run_stats.get_shortest_encounter(act))

 %HighestDamage.text = StringManager.get_string("summary/highest_damage", {damage = run_stats.get_max_damage(act)})

 %ClearanceBox.visible = act == -1
 if act == -1:
  %Clearance.text = StringManager.get_string("summary/difficulty", {
   difficulty = StringManager.get_string("difficulty/clearance", {
    name = StringManager.get_string("difficulty/%s/name" % Game.difficulty)
   })
  })

  var run_info_context: Dictionary = {
   daily = Game.active_daily != null, 
   seed = Game.main.rng.game.get_seed_hex()
  }
  if Game.active_daily:
   run_info_context.merge(Game.active_daily.date)

  %Info.text = StringManager.get_string("summary/run_info_string", run_info_context)

 %PrimarySummary.custom_minimum_size.y = 231 if act == -1 else 0
 %Fights.visible = act == -1
 %Spells.visible = act == -1
 %Words.visible = act == -1

 if act == -1:
  var existing_fights = %FightsContainer.get_children()

  for encounter in run_stats.get_encounters():
   var fight: FightSummary = existing_fights.pop_front()
   if fight == null or fight.is_queued_for_deletion():
    fight = FIGHT_SUMMARY.instantiate()
    %FightsContainer.add_child(fight)

   fight.set_encounter("summary/encounter", encounter)

  for fight in existing_fights:
   %FightsContainer.remove_child(fight)
   fight.queue_free()

  %Spells.visible = not run_stats.spell_usages.is_empty()

  var existing_spells = %SpellsContainer.get_children()
  for id in run_stats.spell_usages:
   var label: Label = existing_spells.pop_front()
   if label == null or label.is_queued_for_deletion():
    label = SUMMARY_LABEL.instantiate()
    %SpellsContainer.add_child(label)

   label.text = StringManager.get_string("summary/spell_usage", {
    spell = StringManager.get_string("spell/%s/name" % id), 
    times_used = run_stats.spell_usages[id]
   })

  for label in existing_spells:
   %SpellsContainer.remove_child(label)
   label.queue_free()

  var run_words: = run_stats.get_words()
  %Words.visible = not run_words.is_empty()

  var existing_words = %WordsContainer.get_children()
  for word in run_words:
   var label: Label = existing_words.pop_front()
   if label == null or label.is_queued_for_deletion():
    label = SUMMARY_LABEL.instantiate()
    %WordsContainer.add_child(label)

   label.text = word

  for label in existing_words:
   %WordsContainer.remove_child(label)
   label.queue_free()

  %Fights.custom_minimum_size.y = 231 if ( %Spells.visible or %Words.visible) else 216

 update_panels.call_deferred()
