@tool
extends BackgroundChunk


const LIGHT_MASK_MATERIAL = preload("res://data/materials/hallway_light_mask.tres")


var sky_dark_opacity: float = 0.0:
 set(value):
  cloud_near_dark_opacity = value
  update_dark_opacity(&"sky")
var cloud_far_dark_opacity: float = 0.0:
 set(value):
  cloud_near_dark_opacity = value
  update_dark_opacity(&"cloud_far")
var cloud_near_dark_opacity: float = 0.0:
 set(value):
  cloud_near_dark_opacity = value
  update_dark_opacity(&"cloud_near")

var foreground_dark_opacity: float = 0.0:
 set(value):
  foreground_dark_opacity = value
  update_dark_opacity()


func _ready():
 super._ready()

 if not Engine.is_editor_hint():
  get_tree().node_added.connect(_on_tree_node_added)


func _on_color_change_marker_triggered() -> void :
 var darkenable_nodes = get_tree().get_nodes_in_group("nobody_darkenable")

 for node in darkenable_nodes:
  create_dark(node)

 for property in ["sky_dark_opacity", "cloud_far_dark_opacity", "cloud_near_dark_opacity", "foreground_dark_opacity"]:
  var tween: = create_tween()
  tween.set_ease(Tween.EASE_IN_OUT)
  tween.tween_property(self, property, 1.0, 3.0)

  if property == "foreground_dark_opacity":
   for spawner in get_tree().get_nodes_in_group("act_3_particle_spawner"):
    tween.parallel().tween_property(spawner, "color", Color(3465577727), 3.0)
  else:
   await Game.timeout(0.25)


func _on_tree_node_added(node: Node) -> void :
 if node.is_in_group("nobody_darkenable"):
  create_dark(node)


func update_dark_opacity(group: StringName = &"nobody_darkenable") -> void :
 for node in get_tree().get_nodes_in_group(group):
  update_node_dark_opacity(node)


func update_node_dark_opacity(node: Node) -> void :
 if node.is_in_group("sky"):
  set_node_dark_opacity(node, sky_dark_opacity)
 elif node.is_in_group("cloud_far"):
  set_node_dark_opacity(node, cloud_far_dark_opacity)
 elif node.is_in_group("cloud_near"):
  set_node_dark_opacity(node, cloud_near_dark_opacity)
 else:
  set_node_dark_opacity(node, foreground_dark_opacity)


func set_node_dark_opacity(node: Node, opacity: float) -> void :
 if node.has_meta("nobody_dark_node"):
  var clone: CanvasItem = node.get_meta("nobody_dark_node")
  clone.modulate.a = opacity

 if node.has_meta("nobody_light_node"):
  var clone: CanvasItem = node.get_meta("nobody_light_node")
  clone.modulate.a = opacity



func create_dark(node: Node) -> void :
 if node.has_meta("nobody_dark_node"):
  return

 if node.texture == null:
  return

 var clones: Array[CanvasItem] = []

 var clone: = create_clone(node, false)
 node.add_child(clone)
 clones.append(clone)

 if node.is_in_group("light_clone"):
  var light_clone: = create_clone(node, true)
  node.add_child(light_clone)
  clones.append(light_clone)

 update_node_dark_opacity(node)

 if node is Sprite2D:
  node.texture_changed.connect(_clone_update_texture.bind(node, clones))

 node.draw.connect(_clone_first_draw.bind(node, clones), ConnectFlags.CONNECT_ONE_SHOT)


func create_clone(node: CanvasItem, light: = false) -> CanvasItem:
 var clone: CanvasItem = CopyUtil.instantiate_clone(node)

 if node is Sprite2D:
  clone.centered = node.centered

 if node is TextureRect:
  clone.expand_mode = node.expand_mode
  clone.stretch_mode = node.stretch_mode

 if light:
  node.set_meta("nobody_light_node", clone)
  clone.set_meta("light_clone", true)
  clone.material = LIGHT_MASK_MATERIAL
 else:
  node.set_meta("nobody_dark_node", clone)

 set_texture(node, clone)

 return clone


func set_texture(node: CanvasItem, clone: CanvasItem) -> void :
 var path: String = node.texture.resource_path
 var texture_path: String
 if clone.has_meta("light_clone"):
  texture_path = path.get_base_dir() + "/light/" + path.get_file()
 else:
  texture_path = path.get_base_dir() + "/dark/" + path.get_file()

 clone.texture = load(texture_path)


func _clone_update_texture(node: CanvasItem, clones: Array[CanvasItem]) -> void :
 for clone in clones:
  set_texture(node, clone)


func _clone_first_draw(node: CanvasItem, clones: Array[CanvasItem]) -> void :
 for clone in clones:
  CopyUtil.copy_transform(node, clone)


func _on_sunset_marker_triggered() -> void :
 var sun_anim_player: AnimPlayer = get_tree().get_first_node_in_group("sun_anim_player")
 if sun_anim_player != null:
  sun_anim_player.play_advance("sunset")


func _process(_delta: float) -> void :
 LIGHT_MASK_MATERIAL.set_shader_parameter("mask_world_position", %LightMaskPosition.global_position)
