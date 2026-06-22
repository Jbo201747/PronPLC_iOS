extends "res://source/ui/icon_button.gd"


enum {
 SUBMIT, 
 REROLL_INITIAL, 
 REROLL, 
 PENDING, 
}

var pressed_reroll: bool = false

var state = SUBMIT:
 set(value):
  if value != state:

   state = value
   update_state()

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void :
 update_state()
 Game.main.game_state_updated.connect(update)
 %Button.focus_exited.connect(_focus_exited)
 Util.disable_focus_for_controls([ %Button])


func update() -> void :
 if Game.main.is_game_actionable():
  if Game.word_builder.can_submit():
   state = SUBMIT
  elif Game.word_builder.tiles.size() == 0 and not Game.main.tutorial.active:
   if pressed_reroll:
    state = REROLL
   else:
    state = REROLL_INITIAL
  else:
   state = PENDING
 else:
  state = PENDING

 if state not in [REROLL, REROLL_INITIAL]:
  pressed_reroll = false


func update_state() -> void :
 if state == SUBMIT:
  sprite.frame = 0
 elif state == PENDING:
  sprite.frame = 2
 else:
  sprite.frame = 1

 tooltip_collision.enabled = state != PENDING
 tooltip_collision.red = state == REROLL
 if state == SUBMIT:
  tooltip_collision.string_identifier = "misc/icon_labels/submit"
 elif state == REROLL_INITIAL:
  tooltip_collision.string_identifier = "misc/icon_labels/reroll"
 elif state == REROLL:
  tooltip_collision.string_identifier = "misc/icon_labels/reroll_confirm"

 action_glyph.disabled = state == PENDING


func press(from_input: bool = false) -> void :
 if state == REROLL_INITIAL:
  if from_input:
   %Button.grab_focus()

  pressed_reroll = true

 await super.press()


func _focus_exited() -> void :
 if pressed_reroll:
  pressed_reroll = false
  update()
