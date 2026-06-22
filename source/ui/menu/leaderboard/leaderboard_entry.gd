class_name LeaderboardMenuEntry extends MarginContainer


var entry: Bridge.LeaderboardEntry
var is_initialized: = false


func _ready() -> void :
 SaveManager.updated_settings.connect(_update)


func _update() -> void :
 if is_initialized:
  set_username()
  set_avatar()


func set_leaderboard_entry(to_entry: Bridge.LeaderboardEntry):
 entry = to_entry
 %Rank.text = StringManager.get_string("menu/leaderboard/rank", {rank = entry.global_rank})
 %LongestWord.stat_text = entry.longest_word
 %Turns.stat_text = str(entry.turns_taken)
 if entry.died or entry.forfeited:
  if entry.died:
   %DamageTaken.frame = 4
  else:
   %DamageTaken.frame = 5

  var context = {lost = true, forfeited = entry.forfeited}
  var enemy_act = Enemies.get_act_and_floor(entry.last_enemy)
  if enemy_act != null:
   context.merge({act = enemy_act.act + 1, floor = enemy_act.floor + 1})

  if StringManager.has_string("enemy/" + entry.last_enemy + "/name"):
   context.enemy_name = StringManager.get_string("enemy/" + entry.last_enemy + "/name")

  %DamageTaken.stat_text = StringManager.get_string("summary/leaderboard_entry/act", context)
  %DamageTaken.context = context
 else:
  %DamageTaken.frame = 1
  %DamageTaken.stat_text = str(entry.damage_taken)
 %TimeTaken.stat_text = StringManager.format_time(entry.time_taken)

 var spells = entry.spells.duplicate()
 var spell_data = entry.spell_data.duplicate()
 var spell_controls = %Spells.get_children()
 for spell_control in spell_controls:
  var spell: Variant = spells.pop_front()
  if spell == null:
   spell_control.visible = false
   continue

  var data = spell_data.pop_front()
  spell_control.set_spell(spell, data, entry.format_number, entry.user_id)

 set_username()
 set_avatar()
 is_initialized = true


func set_username():
 var username: = Bridge.get_username(entry.user_id)
 if SaveManager.get_hide_steam_info():
  %Username.text = username[0]
 else:
  %Username.text = username


func set_avatar():
 var avatar_texture = await Bridge.get_avatar(entry.user_id)
 %Avatar.texture = avatar_texture
