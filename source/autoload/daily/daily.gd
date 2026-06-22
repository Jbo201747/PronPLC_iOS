class_name Daily extends RefCounted


var date: Dictionary = {year = -1, month = -1, day = -1}
var character: String = ""
var difficulty: int = -1
var game_seed: int = -1

var forced_enemies: Array[String] = []
var forced_spells: Dictionary = {}
var all_forced_spells: Array[String] = []
var shadow_act_toggles: Dictionary[int, bool] = {}


func set_data(daily_data: Dictionary) -> void :
 character = daily_data.character
 difficulty = daily_data.difficulty
 game_seed = daily_data.seed

 forced_enemies.clear()
 if "enemies" in daily_data:
  assert (validate_forced_enemies(daily_data.enemies), "Daily %s has invalid forced enemies" % date)
  forced_enemies.append_array(daily_data.enemies)

 forced_spells.clear()
 if "spells" in daily_data:
  for act in daily_data.spells:
   forced_spells[act] = {}
   for selection in daily_data.spells[act]:
    assert (validate_forced_spells(daily_data.spells[act][selection]), "Daily %s has invalid forced spells" % date)
    if daily_data.spells[act][selection] is String:
     forced_spells[act][selection] = [daily_data.spells[act][selection]]
    else:
     forced_spells[act][selection] = daily_data.spells[act][selection]

    all_forced_spells.append_array(forced_spells[act][selection])

 if "shadows" in daily_data:
  if daily_data.shadows is bool:
   shadow_act_toggles = {
    0: daily_data.shadows, 
    1: daily_data.shadows, 
    2: daily_data.shadows, 
   }
  else:
   shadow_act_toggles.assign(daily_data.shadows)


func get_identifier() -> String:
 return DailyManager.get_daily_identifier(date)


func get_forced_spells(act: int = -1, selection: int = -1) -> Array[String]:
 if act == -1 and selection == -1:
  return all_forced_spells

 var forced_select_spells: Array[String] = []
 if act in forced_spells and selection in forced_spells[act]:
  forced_select_spells.assign(forced_spells[act][selection])

 return forced_select_spells


func modify_enemy_pool(pool: Array) -> void :
 for enemy in forced_enemies:
  if Enemies.enemy_in_pool(enemy, pool):
   pool.clear()
   pool.append(enemy)
   return


func is_forced_enemy(enemy: String) -> bool:
 return enemy in forced_enemies


func are_shadows_disabled(act: int) -> bool:
 if act not in shadow_act_toggles:
  return false

 return shadow_act_toggles[act] == false


func are_shadows_forced(act: int) -> bool:
 if act not in shadow_act_toggles:
  return false

 return shadow_act_toggles[act] == true



func validate_forced_enemies(enemies: Array) -> bool:
 var list: = Enemies.list()
 var taken_acts_floors: Array[Dictionary] = []
 for enemy in enemies:
  if enemy not in list:
   return false

  var act_and_floor: Variant = Enemies.get_act_and_floor(enemy)
  if act_and_floor == null or act_and_floor in taken_acts_floors:
   return false

  taken_acts_floors.append(act_and_floor)

 return true


func validate_forced_spells(spells: Variant) -> bool:
 return spells is String or spells is Array
