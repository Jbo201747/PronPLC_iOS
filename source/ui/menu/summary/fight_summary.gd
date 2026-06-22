class_name FightSummary extends HBoxContainer

@onready var description: Label = %Description
@onready var stats: Label = %Stats


func set_encounter(description_key: String, encounter: Dictionary) -> void :
 description.text = StringManager.get_string(description_key, {
  enemy = StringManager.get_string("enemy/%s/name" % encounter.enemy_name), 
 })
 stats.text = StringManager.get_string("summary/enemy_stats", {
  damage_taken = encounter.final_hp - encounter.initial_hp, 
  time = StringManager.format_time(encounter.time_spent)
 })
