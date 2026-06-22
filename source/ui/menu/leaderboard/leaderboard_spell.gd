extends Control


@onready var sprite: SpellSprite = %SpellSprite
@onready var tooltip_collision = %MenuTooltipCollision


func set_spell(spell_id: String, spell_data: Variant, spell_data_version: int, user_id: Variant):
 var spell: = Spell._instantiate_spell(spell_id)
 if spell_id == Globals.SPELLS.SSN:
  spell._setup_ssn(user_id)

 if spell_data is PackedByteArray:
  spell.load_binary_data(spell_data, spell_data_version)

 sprite.link_spell(spell)

 tooltip_collision.string_identifier = "spell/spell_title"
 tooltip_collision.context = spell.get_title_context()
