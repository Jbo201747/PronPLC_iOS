extends Status


const LinkColor = Globals.LinkColor

var turns = 1
var link_id = null


func apply(data):
 var set_color = null
 var set_turns = null
 if data is Dictionary:
  if "color" in data:
   set_color = data.color
  if "turns" in data:
   set_turns = data.turns
 elif data != null:
  set_color = data

 if set_color == null:
  set_color = LinkColor.GRAY

 if set_turns == null:
  set_turns = Game.balance.linked_turns

 set_link_id(set_color)
 turns = set_turns


func clear():
 tile.tile_sprite.linked_top.visible = false
 tile.tile_sprite.linked_bottom.visible = false


func get_color_string():
 return StringManager.get_string("misc/linked_color/" + link_id)


func get_tooltip_context():
 return {linked_color = get_color_string(), linked_turns = turns}


func set_link_id(value):
 link_id = value
 tile.tile_sprite.linked_top.visible = true
 tile.tile_sprite.linked_bottom.visible = true
 tile.tile_sprite.linked_top.frame = Globals.LinkFrame[link_id]
 tile.tile_sprite.linked_bottom.frame = Globals.LinkFrame[link_id]


func get_save_data():
 return {
  color = link_id, 
  turns = turns
 }


func load_save_data(data):
 set_link_id(data.color)
 turns = data.get("turns", turns)
