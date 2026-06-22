@tool
extends Node2D


const PADDING = 16
const MINIMUM_SIZE: = 23
const SEGMENT_SIZE: = 18

var tiles: Array[Tile] = []

@onready var sprite: SpellSprite = %SpellSprite
@onready var label: RichTextLabel = %RichTextLabel
@onready var spell_description: HBoxContainer = %SpellDescription
@onready var tile_conversion: MarginContainer = %TileConversion
@onready var banner_box: NinePatchRect = %NinePatchRect
@onready var anim: AnimPlayer = $AnimationPlayer
@onready var left_tile_control: TileControl = %LeftTile
@onready var right_tile_control: TileControl = %RightTile


func reset_tiles() -> void :
 if tiles.is_empty():
  return

 for tile in tiles:
  tile.queue_free()

 tiles.clear()
 update_visible_box()


func update_visible_box() -> void :
 tile_conversion.visible = not tiles.is_empty()
 spell_description.visible = tiles.is_empty()
 tile_conversion.reset_size()
 spell_description.reset_size()
 update_size()


func set_label(string: String):
 label.text = string
 label.reset_size()
 reset_tiles()


func set_spell_sprite(spell: Spell, censored: bool) -> void :
 sprite.link_spell(spell)
 sprite.set_censored(censored)
 reset_tiles()


func set_spell(spell: Spell) -> void :
 set_spell_sprite(spell, false)
 set_label(spell.get_banner_label())


func set_tiles(tile_a: Tile, tile_b: Tile) -> void :
 left_tile_control.set_tile(tile_a)
 right_tile_control.set_tile(tile_b)
 tiles = [tile_a, tile_b]

 update_visible_box()


func is_active() -> bool:
 return visible


func slide_in(spell: Spell = null):
 if spell != null:
  set_spell(spell)

 anim.play("slide_in")


func slide_out():
 await anim.play_until_finished("slide_out")
 reset_tiles()


func set_banner_size(target_size: int):
 var segments_size: = target_size - MINIMUM_SIZE
 var num_segments: int = ceili(float(segments_size) / SEGMENT_SIZE)
 banner_box.size.x = MINIMUM_SIZE + SEGMENT_SIZE * num_segments
 banner_box.position.x = - roundi(banner_box.size.x / 2)


func update_size() -> void :
 var target_size: int
 if spell_description.visible:
  target_size = ceili(spell_description.size.x) + PADDING
 else:
  target_size = ceili(tile_conversion.size.x) + PADDING

 if target_size <= MINIMUM_SIZE:
  set_banner_size(MINIMUM_SIZE)
 else:
  set_banner_size(target_size)


func _on_h_box_container_resized() -> void :
 if not is_node_ready():
  return

 update_size()
