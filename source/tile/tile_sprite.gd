@tool
class_name TileSprite extends Node2D


signal started_3d
signal finished_3d


const SHADES = {
 highlight = Vector2(23, 6), 
 base = Vector2(23, 7), 
 shadow = Vector2(24, 6), 
 darkest = Vector2(25, 7), 
}

const WOOD_VARIANTS = [
 "a", 
 "b", 
 "c", 
]

const WOOD_TEXTURES = [
 preload("res://arte/tiles/wood_tiles_a.png"), 
 preload("res://arte/tiles/wood_tiles_b.png"), 
 preload("res://arte/tiles/wood_tiles_c.png"), 
]

const FISH_WOOD_TEXTURES = [
 preload("res://arte/tiles/fish/wood_fish_a.png"), 
 preload("res://arte/tiles/fish/wood_fish_b.png"), 
 preload("res://arte/tiles/fish/wood_fish_c.png"), 
]

const FISH_FLIPPED_WOOD_TEXTURES = [
 preload("res://arte/tiles/fish/wood_fish_a_flipped.png"), 
 preload("res://arte/tiles/fish/wood_fish_b_flipped.png"), 
 preload("res://arte/tiles/fish/wood_fish_c_flipped.png"), 
]

const PLASTIC_TEXTURE = preload("res://arte/tiles/plastic_tiles.png")

const FISH_PLASTIC_TEXTURE = preload("res://arte/tiles/fish/plastic_fish.png")
const FISH_FLIPPED_PLASTIC_TEXTURE = preload("res://arte/tiles/fish/plastic_fish_flipped.png")

@export var is_fish: = false:
 set(value):
  is_fish = value
  update_texture()
@export var is_evil: = false:
 set(value):
  is_evil = value
  update_texture()
@export var is_charging: = false:
 set(value):
  is_charging = value
  update_texture()
@export var is_flipped: = false:
 set(value):
  is_flipped = value
  update_texture()
@export var tile_type: Globals.TileType = Globals.TileType.DAMAGE:
 set(value):
  tile_type = value
  update_texture()

@export var wood_variant: = 0

var wood_holes_texture = preload("res://arte/tiles/wood_holes.png")
var plastic_holes_texture = preload("res://arte/tiles/plastic_holes.png")
var material_inheritors: Array[CanvasItem] = []

@onready var linked_top: Sprite2D = %LinkedTop
@onready var linked_bottom: Sprite2D = %LinkedBottom
@onready var base_sprite = %BaseSprite
@onready var base_sprite_anim_player = %BaseSpriteAnimPlayer
@onready var bomb_overlay = %BombOverlay
@onready var bruise_mask: Sprite2D = %BruiseMask
@onready var bruise_overlay: Sprite2D = %BruiseOverlay
@onready var tile_overlay = %TileOverlay
@onready var tile_overlay_anim_player = %TileOverlayAnimPlayer
@onready var icicles = %Icicles
@onready var hole_sprite = %HoleSprite
@onready var hole_outline = %HoleOutline
@onready var highlight_sprite = %HighlightSprite
@onready var region_overlay: Sprite2D = %RegionOverlay
@onready var tile_face = %TileFace
@onready var spike: Sprite2D = %Spike
@onready var screw: Sprite2D = %Screw
@onready var shadow_cloner: ShadowCloner = %ShadowCloner
@onready var multiplier_label: Label = %MultiplierLabel
@onready var multiplier_label_anim_player: AnimPlayer = $MultLabelOffset / MultiplierLabel / AnimPlayer


func _ready():
 if not Engine.is_editor_hint():
  wood_variant = randi_range(0, 2)
  material_inheritors = [bruise_overlay]

  var all_children: Array[Node] = Globals.get_all_children(self)
  for child in all_children:
   if child is CanvasItem:
    if child.use_parent_material:
     material_inheritors.append(child)


func get_fish_folder() -> String:
 var folder: String = "res://arte/tiles/fish/"
 if is_evil:
  folder += "evil/"
  if is_charging:
   folder += "charging/"

 return folder


func get_wood_texture() -> Texture2D:
 if is_fish:
  if is_flipped:
   return ResourceLoader.load(get_fish_folder() + "wood_fish_" + WOOD_VARIANTS[wood_variant] + "_flipped.png")
  else:
   return ResourceLoader.load(get_fish_folder() + "wood_fish_" + WOOD_VARIANTS[wood_variant] + ".png")
 else:
  return WOOD_TEXTURES[wood_variant]


func get_plastic_texture() -> Texture2D:
 if is_fish:
  if is_flipped:
   return ResourceLoader.load(get_fish_folder() + "plastic_fish_flipped.png")
  else:
   return ResourceLoader.load(get_fish_folder() + "plastic_fish.png")
 else:
  return PLASTIC_TEXTURE


func set_type(type):
 tile_type = type
 update_texture()


func update_texture() -> void :
 if not is_node_ready():
  return

 if is_fish:
  linked_top.z_index = 0
 else:
  linked_top.z_index = 200

 var main_texture: Texture2D
 if tile_type == Globals.TileType.DAMAGE:
  main_texture = get_wood_texture()
  hole_sprite.texture = wood_holes_texture
 else:
  main_texture = get_plastic_texture()
  hole_sprite.texture = plastic_holes_texture

 base_sprite.texture = main_texture
 bomb_overlay.texture = main_texture
 tile_overlay.texture = main_texture
 bruise_overlay.texture = main_texture


func set_frame(frame: int, hole_frame: int = frame):
 base_sprite.frame = frame
 hole_sprite.frame = hole_frame


func set_deboss_color(color: Color) -> void :
 tile_face.set_deboss_color(color)


func set_highlight(highlight = null):
 if highlight == null:
  highlight_sprite.visible = false
 else:
  highlight_sprite.visible = true
  highlight_sprite.modulate = highlight.color


func set_hole(enabled, offset = Vector2(0, 0)):
 hole_sprite.visible = enabled
 hole_outline.visible = enabled
 material.set_shader_parameter("hole_enabled", enabled)

 var hole_global_position
 if enabled:
  hole_sprite.position = offset
  hole_outline.position = offset
  hole_global_position = hole_sprite.global_position - Vector2(4.0, 4.0)

 for inheritor in material_inheritors:
  inheritor.set_instance_shader_parameter("hole_enabled", enabled)
  if enabled:
   inheritor.set_instance_shader_parameter("hole_local_position", hole_global_position - inheritor.global_position)


func set_shadow_enabled(enabled: bool):
 shadow_cloner.enabled = enabled


func set_multiplier(value: int) -> void :
 if value == 1:
  hide_multiplier()
  return

 if value == -99:
  hide_multiplier_label()
  spike.visible = true
  return

 const multiplier_colors = {
  -1: Color(2913840639), 
  -2: Color(2913840639), 
  2: Color(4290430719), 
  3: Color(4287085567), 
 }

 if value == -1:
  multiplier_label.text = "-x"
 elif value < 0:
  multiplier_label.text = str(value) + "x"
 else:
  multiplier_label.text = "x" + str(value)
 multiplier_label.add_theme_color_override("font_color", multiplier_colors[value])
 if not multiplier_label.visible or multiplier_label_anim_player.current_animation == "disappear":
  multiplier_label_anim_player.play_advance("appear")


func hide_multiplier_label() -> void :
 if multiplier_label.visible:
  multiplier_label_anim_player.play_advance("disappear")


func hide_multiplier() -> void :
 hide_multiplier_label()
 spike.visible = false
