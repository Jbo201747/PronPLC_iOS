class_name PhonebookPortrait extends Control


var active_icon: PhonebookIcon
var active_portrait_sprite: BattleUnitSprite = null
var active_entry: PhonebookEntry = null

@onready var shadow_button: PhonebookShadowButton = %ShadowButton


func _ready() -> void :
 shadow_button.button.toggled.connect(_on_shadow_button_toggled)


func set_icon(icon: PhonebookIcon):
 active_icon = icon

 var save: = SaveManager.get_save()
 save.data.selected_phonebook_entry = icon.entries[0].id

 set_entry(icon.active_entry)
 icon.refresh_entries()
 shadow_button.set_icon(icon)


func set_entry(entry: PhonebookEntry):
 if entry == active_entry:
  if active_portrait_sprite != null:
   active_portrait_sprite.advance_phonebook_animation()

  return

 active_entry = entry

 if not entry.sprite_scene:
  return

 if entry.is_locked():
  %EnemyNameLabel.text = StringManager.get_string("menu/phonebook/locked")
  %Notes.text = StringManager.get_string("menu/phonebook/locked_description")
 else:
  var save: = SaveManager.get_save()
  save.track_enemy_read(entry.id)
  %EnemyNameLabel.text = entry.get_enemy_name()
  %Notes.text = entry.get_description()

 if entry.id in Enemies.PHONEBOOK_UNCLIPPED:
  %SpriteContainer.clip_contents = not Enemies.PHONEBOOK_UNCLIPPED[entry.id]
 elif Enemies.is_shadow(entry.id) and Enemies.get_base_enemy(entry.id) in Enemies.PHONEBOOK_UNCLIPPED:
  %SpriteContainer.clip_contents = not Enemies.PHONEBOOK_UNCLIPPED[Enemies.get_base_enemy(entry.id)]
 else:
  %SpriteContainer.clip_contents = true

 var old_portrait_sprite: = active_portrait_sprite
 active_portrait_sprite = entry.instantiate_sprite()
 %SpriteContainer.add_child(active_portrait_sprite)
 %PortraitBox.custom_minimum_size.y = active_portrait_sprite.get_phonebook_portrait_size().y
 active_portrait_sprite.prep_phonebook_portrait()

 if entry.is_locked():
  active_portrait_sprite.sound_disabled = true
  active_portrait_sprite.modulate = Color.BLACK
  for node in active_portrait_sprite.phonebook_hidden_when_locked:
   node.visible = false

 if not entry.is_locked():
  active_portrait_sprite.hover_area_input.connect(_on_portrait_sprite_hover_area_input)

 if entry.id == Enemies.GREEB:
  active_portrait_sprite.z_index += 5

 if old_portrait_sprite != null:
  if old_portrait_sprite.hover_area_input.is_connected(_on_portrait_sprite_hover_area_input):
   old_portrait_sprite.hover_area_input.disconnect(_on_portrait_sprite_hover_area_input)

  if Enemies.is_enemy_or_shadow(old_portrait_sprite.unit_id, active_portrait_sprite.unit_id):
   active_portrait_sprite.copy_sprite_state(old_portrait_sprite)

  AudioManager.stop_node_sounds(old_portrait_sprite)

 clear_sprite_container()

 if not entry.is_locked():
  AchievementManager.try_unlock_phonebook_finished(true)


func clear_sprite_container(exclude_active: bool = true) -> void :
 for child in %SpriteContainer.get_children():
  if not exclude_active or child != active_portrait_sprite:
   child.queue_free()

 if not exclude_active:
  active_portrait_sprite = null


func _on_shadow_button_toggled(toggled_on: bool) -> void :
 if active_icon == null:
  return

 Game.menu_shake(true)

 if toggled_on:
  AudioManager.play_sound(Sounds.UI.SHADOW_ON)
  set_entry(active_icon.entries[1])
  active_icon.set_entry(active_icon.entries[1])
 else:
  AudioManager.play_sound(Sounds.UI.SHADOW_OFF)
  set_entry(active_icon.entries[0])
  active_icon.set_entry(active_icon.entries[0])

 shadow_button.set_icon(active_icon)


func _on_portrait_sprite_hover_area_input(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void :
 if event.is_action_pressed("primary_button"):
  active_portrait_sprite.advance_phonebook_animation()
