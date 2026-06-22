@tool
class_name AnimRef extends Resource


@export_node_path("AnimationPlayer") var anim_player: NodePath = NodePath()
@export var anim_name: StringName = &""


func get_player(node: Node) -> AnimationPlayer:
 if node is AnimationMixer:
  var root_node: Node = node.get_node(node.root_node)
  if root_node == null:
   return null
  else:
   return root_node.get_node_or_null(anim_player)
 else:
  return node.get_node_or_null(anim_player)


func play(node: Node) -> void :
 var player: = get_player(node)
 if player == null:
  push_error("Couldn't find animation player! Path: ", anim_player, ", From: ", node.get_path())
  return

 if player is AnimPlayer:
  player.play_advance(anim_name)
 else:
  player.play(anim_name)
