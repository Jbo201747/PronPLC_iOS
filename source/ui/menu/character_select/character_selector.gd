class_name CharacterSelector extends MenuPanel

signal selected

const CHARACTERS = Globals.CHARACTERS
const CHAR_ORDER = Globals.CHARACTER_ORDER
const ICON_SCENE: PackedScene = preload("res://source/ui/menu/character_select/character_selector_icon.tscn")

var icons: Array[CharacterSelectorIcon] = []
var icons_instantiated: = false
var selected_character: String = ""
var selected_is_unlocked: = false

@onready var icon_selector: IconSelector = %IconSelector


func instantiate_icons() -> void :
 for id in CHAR_ORDER:
  var icon: CharacterSelectorIcon = ICON_SCENE.instantiate()
  icon.set_character(id, Globals.is_character_trans(id, get_character_difficulty(id)))
  icons.append(icon)

 var selector_icons: Array[SelectorIcon] = []
 selector_icons.assign(icons)
 icon_selector.set_icons(selector_icons)
 icons_instantiated = true


func prep_character_sprite(id: String, is_trans: bool):
 var character_sprite_scene: PackedScene = load("res://source/characters/sprites/" + id + "_sprite.tscn")
 var photo_mask: Node2D = %PhotoMask
 for child in photo_mask.get_children():
  child.queue_free()

 var character_sprite: CharacterSprite = character_sprite_scene.instantiate()
 character_sprite.is_trans = is_trans

 photo_mask.add_child(character_sprite)
 character_sprite.z_index = 0

 if character_sprite.is_trans and character_sprite.trans_photo_marker != null:
  character_sprite.position = - character_sprite.trans_photo_marker.position
 else:
  character_sprite.position = - character_sprite.photo_marker.position

 if character_sprite.has_node("Sprite"):
  var sprite: = character_sprite.get_node("Sprite")
  var cloner: = ShadowCloner.new()
  cloner.position = Vector2(2.0, 2.0)
  cloner.local_shadow = true
  sprite.add_child(cloner)

 if selected_is_unlocked:
  character_sprite.modulate = Color.WHITE
 else:
  character_sprite.modulate = Color.BLACK


func select_character(id: String):
 selected_character = id
 selected_is_unlocked = Globals.is_character_unlocked(id)
 update_character()
 selected.emit()


func get_character_difficulty(character: String) -> int:
 return SaveManager.get_save().data.selected_character_difficulty.get(character, 0)


func update_character() -> void :
 var id = selected_character
 var character_difficulty = get_character_difficulty(id)
 var is_trans = Globals.is_character_trans(id, character_difficulty)

 prep_character_sprite(id, is_trans)

 var context = {trans = is_trans}
 if selected_is_unlocked:
  %TitleLabel.text = StringManager.get_string("menu/character_select/title", {
   title = StringManager.get_string("character/%s/title" % id, context)
  })
  %DescriptionLabel.text = StringManager.get_string("character/%s/description" % id, context)
  %SpellSprite.modulate = Color.WHITE
  %InfoSprite.modulate = Color.WHITE
 else:
  %TitleLabel.text = StringManager.get_string("menu/character_select/locked")
  %DescriptionLabel.text = StringManager.get_string("achievements/unlock_%s/unlock" % id, {locked = true})
  %SpellSprite.modulate = Color.BLACK
  %InfoSprite.modulate = Color.BLACK

 %NameLabel.text = char_string_or_locked("name", context)
 %SexLabel.text = char_string_or_locked("sex", context)
 %HeightLabel.text = char_string_or_locked("height", context)
 %WeightLabel.text = char_string_or_locked("weight", context)
 %OccupationLabel.text = char_string_or_locked("occupation", context)

 var spell_id = Globals.CHARACTER_SPELLS[id][0]
 var spell: = Spell._instantiate_spell(spell_id)
 if character_difficulty == 10:
  spell.set_curse(Globals.SPELL_CURSES.CURSED)

 %SpellSprite.link_spell(spell)
 %SpellName.text = string_or_locked("spell/" + spell_id + "/name", {curse = "cursed" if character_difficulty == 10 else ""})
 %SpellDescription.text = char_string_or_locked("spell_description")

 %InfoTitle.text = char_string_or_locked("info_title")
 %InfoLabel.text = char_string_or_locked("info")


func char_string_or_locked(string_id: String, context: Dictionary = {}, locked_id: String = "menu/character_select/unknown") -> String:
 return string_or_locked(
  "character/%s/%s" % [selected_character, string_id], 
  context, 
  locked_id
 )


func string_or_locked(string_id: String, context: Dictionary = {}, locked_id: String = "menu/character_select/unknown") -> String:
 if selected_is_unlocked:
  if StringManager.has_string(string_id):
   return StringManager.get_string(string_id, context)
  else:
   return StringManager.get_string(locked_id)
 else:
  return StringManager.get_string(locked_id)


func _on_start_appearing() -> void :
 if not icons_instantiated:
  instantiate_icons()

 update_character_icons()

 selected_character = SaveManager.get_save_data().selected_character
 if selected_character not in CHARACTERS.values() or not Globals.is_character_unlocked(selected_character):
  selected_character = CHARACTERS.LEXICOGRAPHER

 icon_selector.set_initial_selection(CHAR_ORDER.find(selected_character))
 select_character(selected_character)


func update_character_icons() -> void :
 for icon in icons:
  icon.set_character(icon.character, Globals.is_character_trans(icon.character, get_character_difficulty(icon.character)))


func _on_icon_selector_selected(icon: CharacterSelectorIcon) -> void :
 select_character(icon.character)


func _on_difficulty_updated() -> void :
 update_character_icons()
 update_character()


func get_focus_controls() -> Array[Control]:
 return [icon_selector]
