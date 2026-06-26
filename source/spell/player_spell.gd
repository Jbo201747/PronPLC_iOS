class_name PlayerSpell extends Node2D

signal despawned

const CURSES = Globals.SPELL_CURSES


var spell: Spell

@onready var spell_paper: SpellPaper = %SpellPaper
@onready var spell_sprite: SpellSprite = %SpellSprite
@onready var charge_container: ChargeContainer = %ChargeContainer
@onready var tooltip_collision = %TooltipCollision
@onready var label = %Label
@onready var action_glyph: ActionGlyph = %ActionGlyph

@onready var player = Game.player
@onready var word_builder = Game.word_builder
@onready var main = Game.main


func _ready() -> void :
 player.selection_started.connect(_on_player_selection_started)
 main.game_state_updated.connect(update)


func _process(delta: float) -> void :
 if spell.has_process:
  spell._process(delta)


func set_spell(_spell: Spell) -> void :
 spell = _spell
 spell.player_spell_slot = self
 charge_container.link_spell(_spell)
 spell_sprite.link_spell(_spell)
 spell_paper.set_cursed(spell.is_cursed())

 spell.charge_updated.connect(_on_spell_charge_updated)
 spell.description_updated.connect(_on_spell_description_updated)
 spell.set_ready()

 _on_spell_charge_updated()
 _on_spell_description_updated()


func update_glyph_action(index: int) -> void :
 action_glyph.action = "spell_" + str(index)


func update() -> void :
 if spell.get_laced_damage() > 0:
  spell_sprite.blink_warning()
 else:
  spell_sprite.stop_blinking()

 if player.is_selecting(player.Selection.SPELL):
  spell_paper.set_usable(is_clickable())
 else:
  spell_paper.set_usable(spell.is_usable())

 if is_clickable():
  spell_paper.enable_button()
 elif Util.is_mobile() and Game.main.is_player_turn and spell.is_usable() and player.active_spell == null:
  spell_paper.enable_button()
 else:
  spell_paper.disable_button()


func is_clickable() -> bool:
 if player.is_selecting() and spell.is_active():
  return true
 elif player.is_selecting(player.Selection.SPELL):
  return player.passes_selection_condition(spell)

 return (
  main.is_game_actionable(spell.spell_data.use_while_selecting, false, main.tutorial.allow_spell_use)
  and player.active_spell == null
  and spell.is_usable()
 )


func despawn(fade: = false):
 spell_paper.disable_button()
 tooltip_collision.clear_tooltip()
 tooltip_collision.hide()

 if fade:
  var fade_tween: = create_tween()
  fade_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
  fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
  await fade_tween.finished

 despawned.emit()

 queue_free()


func _on_spell_paper_pressed() -> void :
 if spell.is_active() and player.is_selecting():
  AudioManager.play_sound(Sounds.SPELLS.SPELL_CLICK)
  player.cancel_selection()
  return

 if player.is_selecting(player.Selection.SPELL):
  AudioManager.play_sound(Sounds.SPELLS.SPELL_CLICK)
  player.selected.emit(spell)
  return

 if not spell.spell_data.no_use_sound:
  AudioManager.play_sound(Sounds.SPELLS.SPELL_CLICK)

 await spell.start_using()


func _on_spell_charge_updated() -> void :
 update()


func _on_spell_description_updated() -> void :
 label.text = spell.get_label()


func _on_generate_tooltip(tooltip):
 spell.generate_player_spell_tooltip(tooltip)


func _on_player_selection_started():
 if spell.is_active():
  if not main.spell_banner.is_active():
   main.spell_banner.slide_in(spell)


func _on_spell_paper_focus_entered() -> void :
 if spell and spell.has_method("on_hover"):
  spell.on_hover()


func _on_spell_paper_focus_exited() -> void :
 if spell and spell.has_method("on_unhover"):
  spell.on_unhover()
