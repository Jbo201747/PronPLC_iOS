class_name ShadowCloner extends Node2D

@export var clone_offset: CanvasItem
@export var modulate_source: CanvasItem
@export var modulate_depth: int = 1
@export var local_shadow_group: bool = false
@export var local_shadow: bool = false:
 set(value):
  local_shadow = value
  if clone != null:
   check_offset_camera_transform()
   set_clone_parent()

@export var use_solid_shadow: bool = false:
 set(value):
  if value != use_solid_shadow:
   use_solid_shadow = value
   if clone != null:
    update_clone_material()
@export var awaiting_reparent: bool = false
@export var solid_shadow_color: Color = Color.BLACK:
 set(value):
  if value != solid_shadow_color:
   solid_shadow_color = value
   if clone != null:
    update_clone_material()

var clone: Node = null
var enabled = true:
 set(value):
  enabled = value
  if clone != null and clone is CanvasItem:
   if not enabled:
    clone.visible = false
   else:
    CopyUtil.copy_visibility(get_parent(), clone)

var offset_camera_transform: = false


func _ready():
 if not awaiting_reparent:
  _setup_parent()


func _setup_parent() -> void :
 var was_awaiting_reparent: = awaiting_reparent
 awaiting_reparent = false

 var parent: = get_parent()
 process_priority = parent.process_priority + 1
 if parent is CanvasItem and not was_awaiting_reparent:
  parent.draw.connect(_parent_first_draw, CONNECT_ONE_SHOT)
 else:
  _parent_first_draw()


func _parent_first_draw():
 var parent: = get_parent()
 if parent is CanvasItem:
  parent.draw.connect(_on_parent_redraw)
  parent.visibility_changed.connect(_on_parent_visibility_changed)

  if parent is Sprite2D:
   parent.frame_changed.connect(_on_parent_frame_changed)
   parent.texture_changed.connect(_on_parent_texture_changed)

 clone_parent()


func _notification(what: int) -> void :
 if what == NOTIFICATION_PREDELETE:
  free_clone()


func _process(_delta: float) -> void :
 if clone == null or not enabled:
  return

 update_clone()


func free_clone() -> void :
 if clone != null and is_instance_valid(clone) and not clone.is_queued_for_deletion():
  clone.queue_free()


func update_clone() -> void :
 adjust_clone_modulate()
 CopyUtil.copy_transform(get_parent(), clone)
 adjust_clone_position()


func adjust_clone_modulate() -> void :
 if modulate_source == null:
  CopyUtil.copy_transparency(get_parent(), clone, modulate_depth)
 else:
  CopyUtil.copy_transparency(modulate_source, clone, modulate_depth)


func adjust_clone_position():
 if clone is Node2D:
  clone.transform *= transform
 elif clone is Control:
  clone.position += position

 if clone_offset != null:
  clone.position -= clone_offset.position

 if offset_camera_transform:
  clone.position += Game.get_shake_camera().offset


func _on_parent_redraw():
 if clone == null:
  return

 CopyUtil.copy_light(get_parent(), clone)
 if clone is Sprite2D:
  CopyUtil.copy_sprite_frame(get_parent(), clone)

 update_clone()


func _on_parent_visibility_changed():
 if clone == null or not enabled:
  return

 CopyUtil.copy_visibility(get_parent(), clone)


func _on_parent_frame_changed():
 if clone == null:
  return

 CopyUtil.copy_sprite_frame(get_parent(), clone)


func _on_parent_texture_changed():
 if clone == null:
  return

 CopyUtil.copy_sprite_texture(get_parent(), clone)
 CopyUtil.copy_sprite_frame(get_parent(), clone)


func clone_parent():
 free_clone()

 var parent = get_parent()
 clone = CopyUtil.instantiate_clone(parent)

 if clone == null:
  push_error("ShadowCloner can't clone ", get_parent())
  return

 CopyUtil.copy_full(parent, clone)

 if clone is CanvasItem:
  clone.z_index = 0
  update_clone_material()

  check_offset_camera_transform()

  if not enabled:
   clone.visible = false
  else:
   update_clone()
   CopyUtil.copy_visibility(parent, clone)

 set_clone_parent()


func update_clone_material() -> void :
 var parent = get_parent()

 clone.use_parent_material = false

 if not use_solid_shadow:
  clone.modulate = Color(0.0, 0.0, 0.0, parent.modulate.a)
  clone.material = null
 else:
  clone.modulate = Color(1.0, 1.0, 1.0, parent.modulate.a)
  clone.material = preload("res://source/ui/generic/recolor_material.tres")
  clone.set_instance_shader_parameter("recolor", solid_shadow_color.linear_to_srgb())


func check_offset_camera_transform():
 var parent = get_parent()
 var parent_layer: CanvasLayer = parent.get_canvas_layer_node()
 if parent_layer != null and not local_shadow:
  offset_camera_transform = not parent_layer.follow_viewport_enabled
 else:
  offset_camera_transform = false


func set_clone_parent():
 var parent_to: Node = null
 if local_shadow:
  parent_to = self
  clone.position = Vector2.ZERO
  show_behind_parent = true
  if not use_solid_shadow:
   modulate = Color(1.0, 1.0, 1.0, 61.0 / 255.0)
 else:
  if local_shadow_group:
   parent_to = Util.find_first_node_in_parents(self, "%ShadowGroup")
  else:
   parent_to = Game.get_shadow_group()

 if parent_to != null:
  if clone.get_parent() != null:
   clone.reparent(parent_to)
  else:
   parent_to.add_child(clone)
