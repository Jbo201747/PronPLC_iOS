extends Node2D


const Intent = Globals.Intent
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect

const CategoryFrames = {
 Globals.WORD_CATEGORIES.COLORS: 56, 
 Globals.WORD_CATEGORIES.FRUITS_AND_VEGETABLES: 57, 
 Globals.WORD_CATEGORIES.ANIMALS: 58, 
 Globals.WORD_CATEGORIES.METALS: 59, 
 Globals.WORD_CATEGORIES.BODY_PARTS: 60, 
}

const IntentFrame = {

 Intent.PLAYER_BRUISE: 7, 


 Intent.DAMAGE: 40, 
 Intent.DAMAGE_MULTIPLIER: 41, 
 Intent.DEFENSE: 42, 
 Intent.DEFENSE_MULTIPLIER: 43, 
 Intent.PERIOD: 13, 
 Intent.SHIMMERING: 3, 
 Intent.CAPITAL: 14, 
 Intent.LINKED: 12, 
 Intent.ACID: 6, 
 Intent.BRUISE: 7, 
 Intent.BLEED: 9, 
 Intent.STRAIGHT: 15, 
 Intent.POISON: 16, 
 Intent.HEAL: 24, 
 Intent.BOMB: 30, 
 Intent.CURSED: 33, 
 Intent.REPEAT_WORD: 3, 
 Intent.LACED: 13, 
 Intent.HAZE: 17, 
 Intent.ETERNAL: 48, 
 Intent.CRIT_CHANCE: 49, 
 Intent.SPIKED_SLOTS: 71, 


 Intent.PARRY: 1, 
 Intent.DOUBLESPEAK: 4, 
 Intent.DREAM: 8, 
 Intent.CURSED_CAPITAL: 33, 
 Intent.POISON_SCRAMBLE: 54, 
 Intent.PADDLE: 18, 
 Intent.SUIT_PADDLE: 52, 
 Intent.LOCK_RESTOCK: 25, 
 Intent.FEED: 64, 
 Intent.BLEED_WILDCARD: 66, 
 Intent.KEYPAD: 61, 
 Intent.PASSCODE: 62, 
 Intent.FILTER: 65, 
 Intent.BLOW: 67, 
 Intent.TICKING: 30, 
 Intent.DETONATE: 31, 
 Intent.SPRAWL: 32, 
 Intent.ABDUCT: 34, 
 Intent.SWAP_TYPE: 63, 
 Intent.MULTITUDE: 35, 
 Intent.TRAFFIC: 50, 
 Intent.BITE: 36, 
 Intent.BLEED_CURSE: 55, 
 Intent.APPLY_ETERNAL: 48, 
 Intent.BLEED_FULL_WORD: 53, 
 Intent.HOLE_PUNCH: 38, 
 Intent.MYSTERY_CRIT: 39, 
 Intent.ATTACK: 44, 
 Intent.HARMLESS_ATTACK: 69, 
 Intent.DEFEND: 45, 


 Intent.EXPAND_BOARD: 11, 
 Intent.SHRINK_BOARD: 11, 
 Intent.LETTER_OPENER: 0, 
 Intent.BOARD_SHEAR: 21, 
 Intent.CLEAR_BOARD: 11, 
 Intent.CURSE_BOARD: 11, 
 Intent.CONCENTRATION: 2, 
 Intent.ACID_BOMB: 14, 
 Intent.PREPARING: 3, 
}

const SpecialIntentFrame = {
 "menstruate": 37, 
 "coagulate": 46, 
 "coagulate_trigram": 47, 
 "frozen_slashed": 68, 
 "wildcard_chance": 70, 
 "big_intestine": 28, 
 "small_intestine": 29, 
}

const StatusIntentFrame = {
 TileStatus.CRIT: 4, 
 TileStatus.SPICY: 5, 
 TileStatus.ACID: 6, 
 TileStatus.BRUISE: 7, 
 TileStatus.ASH: 8, 
 TileStatus.BLEED: 9, 
 TileStatus.FROZEN: 10, 
 TileStatus.POISON: 16, 
 TileStatus.GAY: 18, 
 TileStatus.POOP: 20, 
 TileStatus.GUNK: 22, 
 TileStatus.COAL: 23, 
 TileStatus.CANDY: 24, 
 TileStatus.LINKED: 26, 
 TileEffect.WILDCARD: 27, 
 TileEffect.NUMBER: 51, 
 TileStatus.BOMB: 30, 
 TileStatus.CURSED: 33, 
 TileStatus.HAZE: 17, 
 TileStatus.ETERNAL: 48, 
 TileStatus.MONEY: 19, 
}

const WORD_CATEGORY_INTENTS = [Intent.CATEGORY, Intent.CATEGORY_MATCHED]
const CONTEXT_STATUS_INTENTS = [Intent.APPLY_STATUS, Intent.CONVERT_STATUS]
const BOARD_TARGET_INTENTS = CONTEXT_STATUS_INTENTS


const IntentPriority = {
 Intent.DAMAGE: 0, 
 Intent.DAMAGE_MULTIPLIER: 1, 
 Intent.DEFENSE: 2, 
 Intent.DEFENSE_MULTIPLIER: 3, 
 Intent.HEAL: 4, 
 Intent.LACED: 5, 
 Intent.BOMB: 6, 
 Intent.CURSED: 7, 
 Intent.BLEED: 8, 
 Intent.POISON: 9, 
 Intent.ACID: 10, 
 Intent.HAZE: 11, 
 Intent.ETERNAL: 12, 
 Intent.SPIKED_SLOTS: 15, 
 Intent.LINKED: 30, 
 Intent.CAPITAL: 35, 
 Intent.PERIOD: 40, 
 Intent.SHIMMERING: 45, 
 Intent.CRIT_CHANCE: 100, 
}

const IntentStatusTooltips = {
 Intent.DOUBLESPEAK: [TileStatus.CRIT, TileEffect.SHIMMERING], 
 Intent.DREAM: [TileStatus.ASH], 
 Intent.CURSED_CAPITAL: [TileStatus.CURSED, TileStatus.CAPITAL], 
 Intent.POISON_SCRAMBLE: [TileStatus.POISON], 
 Intent.PADDLE: [TileStatus.GAY], 
 Intent.SUIT_PADDLE: [TileEffect.SUIT, TileStatus.BLEED, TileStatus.ASH], 
 Intent.BLEED_WILDCARD: [TileStatus.BLEED, TileEffect.WILDCARD], 
 Intent.SPRAWL: [{status = TileStatus.ENHANCED, plastic = true}], 
 Intent.BLEED_CURSE: [TileStatus.CURSED], 
 Intent.BLEED_FULL_WORD: [TileStatus.BLEED, TileStatus.CAPITAL, TileStatus.PERIOD], 
 Intent.HOLE_PUNCH: [TileStatus.HOLE], 
 Intent.MYSTERY_CRIT: [{status = TileStatus.CRIT, plastic = true}, TileStatus.MYSTERY], 
 Intent.BOARD_SHEAR: [TileStatus.BLEED], 
 Intent.ACID_BOMB: [TileStatus.ACID, TileStatus.BOMB], 
 Intent.APPLY_ETERNAL: [TileStatus.ETERNAL], 
}

var intent = null
var disappearing: = false
var context: Dictionary = {}
var tiles = []

@onready var sprite = $Sprite
@onready var label = $Label
@onready var anim_player = $AnimPlayer
@onready var tooltip_collision = $TooltipCollision


func get_key() -> String:
 return Intent.keys()[intent].to_lower()


func update_sprite():
 if "name_override" in context and context.name_override in SpecialIntentFrame:
  sprite.frame = SpecialIntentFrame[context.name_override]
 elif intent in IntentFrame:
  sprite.frame = IntentFrame[intent]
 elif intent in WORD_CATEGORY_INTENTS:
  sprite.frame = CategoryFrames[context.word_category]
 elif intent in CONTEXT_STATUS_INTENTS:
  for status in get_statuses():
   if status in StatusIntentFrame:
    sprite.frame = StatusIntentFrame[status]
    break


func get_priority():
 if intent in IntentPriority:
  return IntentPriority[intent]
 else:
  return 99


func matches(other_intent, other_context):
 if intent != other_intent:
  return false

 if intent in CONTEXT_STATUS_INTENTS:
  return get_statuses() == get_statuses(other_context)
 else:
  return true


func get_statuses(from_context: Dictionary = context) -> Array:
 var statuses: Array = []
 if "statuses" in from_context:
  statuses = from_context.statuses
 elif "status" in from_context:
  statuses.append(from_context.status)

 return statuses


func get_tooltip_context() -> Dictionary:
 var use_context: = context.duplicate()
 if intent in CONTEXT_STATUS_INTENTS:
  var statuses: = get_statuses()
  if not statuses.is_empty():
   use_context.status_names = []
   for status in statuses:
    use_context.status_names.append(StringManager.get_string("status/" + status + "/name", use_context))

   if statuses[-1] in Globals.PLURALIZE_EFFECTS:
    use_context.status_plural = true

 if intent in WORD_CATEGORY_INTENTS:
  use_context.category_name = StringManager.get_string("intent/word_categories/" + use_context.word_category + "/name")
  use_context.category_singular = StringManager.get_string("intent/word_categories/" + use_context.word_category + "/singular")

 if intent in BOARD_TARGET_INTENTS:
  if "target" in use_context:
   use_context.target = StringManager.get_string("intent/board_targets/" + use_context.target, use_context)
  else:
   use_context.target = StringManager.get_string("intent/board_targets/default", use_context)

 return use_context


func _on_generate_tooltip(tooltip):
 var use_context: = get_tooltip_context()
 var name_key: String = get_key()
 var description_key: String = get_key()
 if "name_override" in use_context and StringManager.has_string("intent/" + use_context.name_override + "/name"):
  name_key = use_context.name_override

 if not StringManager.has_string("intent/" + name_key + "/name"):
  return

 if "description_override" in use_context:
  description_key = use_context.description_override

 tooltip.add_subtooltip(
  StringManager.get_string("intent/" + name_key + "/name", use_context), 
  StringManager.get_string("intent/" + description_key + "/description", use_context)
 )

 if intent not in IntentStatusTooltips and intent not in CONTEXT_STATUS_INTENTS:
  return

 var status_subtooltips = get_statuses()
 if intent in IntentStatusTooltips:
  status_subtooltips.append_array(IntentStatusTooltips[intent])

 for status in status_subtooltips:
  var status_id = status
  if status is Dictionary:
   status_id = status.status

  if not StringManager.has_string("status/" + status_id + "/description"):
   continue

  var status_context: Dictionary = context.duplicate()
  status_context.merge({intent = true, value = "X"})
  if status is Dictionary:
   status_context.merge(status)

  tooltip.add_subtooltip(
   StringManager.get_string("status/" + status_id + "/name", use_context), 
   StringManager.get_string("status/" + status_id + "/description", use_context)
  )


func get_label():
 var key = get_key()
 if StringManager.has_string("intent/" + key + "/label"):
  return StringManager.get_string("intent/" + key + "/label", context)
 else:
  return StringManager.get_string("intent/default_label", context)


func set_intent(to, intent_context = {}, intent_tiles = []):
 intent = to
 set_context(intent_context, intent_tiles)
 update_sprite()
 update_label()


func set_context(intent_context, intent_tiles):
 context = intent_context
 set_tiles(intent_tiles)


func set_tiles(_tiles):
 for tile in tiles:
  if tile not in _tiles:
   clear_tile_highlight(tile)

 tiles = _tiles


func update_label():
 label.text = get_label()


func appear(instant: = false) -> void :
 anim_player.play_advance("appear", instant)


func disappear(instant: = false):
 if disappearing:
  push_warning("Intent disappear called twice")
  return

 disappearing = true
 clear_highlights()
 tiles = []

 if not instant:
  anim_player.play("disappear")
  await anim_player.animation_finished

 queue_free()


func clear_tile_highlight(tile):
 if Tile.is_tile_valid(tile):
  tile.clear_highlight(self)


func clear_highlights():
 for tile in tiles:
  clear_tile_highlight(tile)


func _on_tooltip_collision_hovered_on():
 if disappearing:
  return

 for tile in tiles:
  if is_instance_valid(tile):
   tile.add_highlight(self)
  else:
   push_warning("Attempting to highlight null tile ", tile)


func _on_tooltip_collision_hovered_off():
 if Game.main != null and Game.main.tutorial.active:
  if %TooltipCollision.is_displaying and "hover_intent" in Game.main.tutorial.current_line_flags:
   Game.main.tutorial.advance()

 if disappearing:
  return

 clear_highlights()


func _exit_tree():
 clear_highlights()


func _on_tooltip_collision_check_generate_tooltip(tooltip: Variant) -> void :
 tooltip.enabled = StringManager.has_string("intent/" + get_key() + "/name")
