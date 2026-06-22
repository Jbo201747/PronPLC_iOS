class_name CopyUtil


const IGNORED_PROPERTIES = [
 "owner", "name", "unique_name_in_owner", 
 "scene_file_path", "editor_description", "script", 
 "anchor_left", "anchor_right", "anchor_top", "anchor_bottom", 
 "offset_left", "offset_right", "offset_top", "offset_bottom", 
 "material", 
]


static func copy_full(from: Object, onto: Object, copy_name: bool = false) -> void :
 if copy_name:
  if from is Node and onto is Node:
   onto.name = from.name

 for property in from.get_property_list():
  if property.name in IGNORED_PROPERTIES:
   continue

  if property.usage in [PROPERTY_USAGE_GROUP, PROPERTY_USAGE_SUBGROUP, PROPERTY_USAGE_CATEGORY]:
   continue
  elif property.usage & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_INTERNAL) != 0:
   continue

  onto.set(property.name, from.get(property.name))


static func copy_light(from: Node, onto: Node) -> void :
 if onto is Label or onto is RichTextLabel:
  onto.text = from.text
  onto.visible_characters = from.visible_characters

 if onto is CanvasItem:
  copy_transform(from, onto)


static func copy_transform(from: CanvasItem, onto: CanvasItem) -> void :
 if onto is Node2D:
  onto.global_transform = from.global_transform
 elif onto is Control:
  var global_transform: = from.get_global_transform()
  onto.scale = global_transform.get_scale()
  onto.size = from.size
  onto.rotation = global_transform.get_rotation()
  onto.global_position = global_transform.get_origin()

 if onto is Sprite2D:
  onto.offset = from.offset


static func copy_visibility(from: CanvasItem, onto: CanvasItem) -> void :
 onto.visible = from.is_visible_in_tree()


static func get_combined_alpha(node: CanvasItem, depth: int = -1) -> float:
 if depth == 1:
  return node.modulate.a

 var alpha: = node.modulate.a
 var iterations: int = 1
 var parent: = node.get_parent()
 while parent != null and parent is CanvasItem:
  alpha *= parent.modulate.a
  iterations += 1
  if depth != -1 and iterations >= depth:
   break

  parent = parent.get_parent()

 return alpha


static func copy_transparency(from: CanvasItem, onto: CanvasItem, depth: int = 1) -> void :
 onto.modulate.a = get_combined_alpha(from, depth)
 onto.self_modulate.a = from.self_modulate.a


static func copy_sprite_frame(from: Sprite2D, onto: Sprite2D) -> void :
 onto.hframes = from.hframes
 onto.vframes = from.vframes
 onto.frame = from.frame
 onto.region_enabled = from.region_enabled
 onto.region_rect = from.region_rect


static func copy_sprite_texture(from: Sprite2D, onto: Sprite2D) -> void :
 onto.texture = from.texture


static func instantiate_clone(object: Object) -> Object:
 return ClassDB.instantiate(object.get_class())
