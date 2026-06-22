class_name SpellSelectSpell extends MenuPanel


signal selected

const CURSES = Globals.SPELL_CURSES

var spell: Spell
var is_censored: = false
var selection_completed: = false

@onready var spell_sprite: SpellSprite = %SpellSprite
@onready var censored_sprite: Sprite2D = %CensoredSprite
@onready var charge_container: ChargeContainer = %ChargeContainer
@onready var name_label: Label = %NameLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var button: Button = %Button

@onready var spell_container: = Game.spell_container


func _process(delta: float) -> void :
 if spell and spell.has_process_select:
  spell._process_select(delta)


func set_spell(_spell: Spell) -> void :
 selection_completed = false
 spell = _spell
 spell_sprite.link_spell(spell)

 charge_container.link_spell(spell)
 spell.description_updated.connect(update_labels)
 spell.set_ready()

 update()


func unlink_spell() -> void :
 if spell == null:
  return
 elif not is_instance_valid(spell):
  spell = null
  return

 spell_sprite.unlink_spell()
 charge_container.unlink_spell()
 Util.disconnect_signal(spell.description_updated, update_labels)

 spell = null


func finish_disappear() -> void :
 unlink_spell()
 super.finish_disappear()


func set_left_tooltip() -> void :
 var tooltip_collision = %TooltipCollision
 tooltip_collision.horizontal_alignment = tooltip_collision.TooltipHorizontalAlignment.LEFT
 tooltip_collision.position_offset.x = - tooltip_collision.position_offset.x


func update(no_censor: = false):
 is_censored = spell.has_curse(CURSES.CENSORED) and not no_censor
 if spell.is_cursed():
  panel.theme_type_variation = "SpellSelectCursed"
 else:
  panel.theme_type_variation = "SpellSelectPanel"

 if spell.has_curse(CURSES.NOSTALGIC):
  spell_sprite.blink_warning()
 elif spell.has_curse(CURSES.SHINY):
  spell_sprite.flash_shiny()
 else:
  spell_sprite.stop_blinking()

 update_sprite()
 update_labels()


func update_sprite() -> void :
 spell_sprite.set_censored(is_censored)


func update_labels() -> void :
 if is_censored:
  name_label.text = StringManager.get_string("curse/censored/redacted")
  description_label.text = StringManager.get_string("curse/censored/description")
 else:
  name_label.text = spell.get_title()
  description_label.text = spell.get_description()

 Util.shrink_label_to_bounds(name_label, 90, 7)


func select(replacing_spell: Spell = null):
 if spell.has_curse(CURSES.SHINY):
  var replaceable_spells: Array[Spell] = []
  for owned_spell: Spell in Game.player.get_spells():
   if not owned_spell.spell_data.character_specific:
    replaceable_spells.append(owned_spell)


  if not replaceable_spells.is_empty():
   replacing_spell = spell.rng.shiny.pick_random(replaceable_spells)

 if replacing_spell != null:
  AchievementManager.replaced_spell(replacing_spell)
  Game.spell_container.replace_spell(replacing_spell, spell)
 else:
  Game.spell_container.add_spell(spell)

 if spell.id == Globals.SPELLS.REPLACEMENT_CHARACTER:
  Game.main.remove_spell_from_pool(spell.id)

 var player_spell: PlayerSpell = Game.spell_container.find_spell(spell)

 spell._gain()


 spell = player_spell.spell
 player_spell.spell_paper.gain()

 spell.player_spell_slot.charge_container.charge_tiles()
 spell.just_added = true

 complete_selection()


func complete_selection() -> void :
 AchievementManager.selected_spell(spell)
 visible = false
 selected.emit()


func cancel_selection() -> void :
 pass


func _on_button_pressed() -> void :
 if selection_completed:
  return

 AudioManager.play_sound(Sounds.SPELLS.SPELL_CLICK)

 var player = Game.player
 var main = Game.main
 if player.is_selecting():

  var should_return = spell.is_active()
  player.cancel_selection()
  if should_return:
   return

 @warning_ignore("redundant_await")
 var skip_normal_select: = await spell.spell_select(self)
 if skip_normal_select:
  return

 if player.has_max_spells() and not spell.has_curse(CURSES.SHINY):
  main.spell_banner.set_spell_sprite(spell, is_censored)
  main.spell_banner.set_label(StringManager.get_string("spell/spell_select_banner"))
  main.spell_banner.slide_in()

  player.set_active_spell(spell)
  var replacing_spell = await player.get_selection(player.Selection.SPELL, func(_spell: Spell): return not _spell.spell_data.character_specific)
  player.set_active_spell(null)

  main.spell_banner.slide_out()

  if replacing_spell != null and not replacing_spell.spell_data.character_specific:
   select(replacing_spell)
  else:
   cancel_selection()
 else:

  select()


func get_focus_controls() -> Array[Control]:
 return [button]


func _on_button_focus_entered() -> void :
 if spell and spell.has_method("on_hover"):
  spell.on_hover()


func _on_button_focus_exited() -> void :
 if spell and spell.has_method("on_unhover"):
  spell.on_unhover()


func _on_tooltip_collision_generate_tooltip(tooltip: Variant) -> void :
 spell.generate_spell_select_tooltip(tooltip)


func _on_tooltip_collision_check_generate_tooltip(tooltip_collision: Variant) -> void :
 tooltip_collision.enabled = spell.has_spell_select_tooltip()
