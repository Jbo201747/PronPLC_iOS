class_name SpellStatsEntry extends Control


var spell: Spell
var taken: int = 0
var used: int = 0

@onready var sprite: SpellSprite = %SpellSprite
@onready var tooltip_collision = %MenuTooltipCollision


func set_spell(id: String) -> void :
 spell = Spell._instantiate_spell(id)
 sprite.link_spell(spell)


func update_stats() -> void :
 var save: = SaveManager.get_save()
 var stats: Dictionary = save.get_spell_stats(spell.id, -1, false)
 var max_difficulty: = save.get_spell_max_difficulty(spell.id)
 if spell.id in Globals.MERGED_SPELL_STATS:
  var merged_id: String = Globals.MERGED_SPELL_STATS[spell.id]
  var other_stats: Dictionary = save.get_spell_stats(merged_id, -1, false)
  max_difficulty = maxi(max_difficulty, save.get_spell_max_difficulty(merged_id))
  Util.sum_dictionaries(stats, other_stats, true)

 if spell.id == Globals.SPELLS.RED_LETTER:
  for id in Globals.RED_LETTER_SPELLS:
   max_difficulty = maxi(max_difficulty, save.get_spell_max_difficulty(id))

 taken = stats.taken
 used = stats.used

 if spell.id in Globals.HIDDEN_SPELLS and stats.taken <= 0:
  visible = false
  return

 visible = true
 if stats.taken <= 0:
  %StatsContainer.visible = false
  sprite.modulate = Color.BLACK
  tooltip_collision.string_identifier = "menu/stats/not_found"
  return
 else:
  %StatsContainer.visible = true
  sprite.modulate = Color.WHITE
  tooltip_collision.string_identifier = "spell/spell_title"
  tooltip_collision.context = spell.get_title_context()

 if max_difficulty == -1:
  %MaxDifficulty.modulate = Color.BLACK
 else:
  %MaxDifficulty.modulate = Color.WHITE
  %MaxDifficulty.frame = max_difficulty

 %Taken.stat_text = str(stats.taken)
 %Found.stat_text = str(stats.found)
 %Used.stat_text = str(stats.used)
 %Wins.stat_text = str(stats.wins)
