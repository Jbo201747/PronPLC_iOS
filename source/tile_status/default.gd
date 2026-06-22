class_name Status extends RefCounted

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus

var tile: Tile = null
var id: String = ""

var is_exclusive: bool = true
var is_harmful: bool = false
var faceless: bool = false
var face_status: bool = false
var override_default_title: bool = false
var destroy_on_turn_end: bool = false
var prevents_falling: bool = false
var indestructible: bool = false
var no_faceless_effect: bool = false
var space: bool = false
var spray_exempt: bool = false
var spray_destroys: bool = false
var type_unique_status: bool = false
var exclusive_with: = PackedStringArray()
var priority: int = INT64_MIN
var has_process: = false


static func create(_id: String) -> Status:
 var filepath: = "res://source/tile_status/" + _id + ".gd"
 if ResourceLoader.exists(filepath):
  var script: GDScript = load(filepath)
  return script.new(_id)
 else:
  return new(_id)


static func status_is_exclusive(_id: String) -> bool:
 if not StringManager.has_string("status/%s/flags" % _id):
  return true

 return "shared" not in StringManager.get_string("status/%s/flags" % _id).split(" ", false)


func _init(_id: String) -> void :
 id = _id
 var group: = StringManager.get_string_group("status/" + id)
 if group != null:
  if group.has_string("exclusive_with"):
   exclusive_with = group.get_string("exclusive_with").split(" ", false)

  if group.has_string("flags"):
   var flags: = group.get_string("flags").split(" ", false)
   for flag in flags:
    if flag == "shared":
     is_exclusive = false
    elif flag == "harmful":
     is_harmful = true
    elif flag == "no_faceless_effect":
     no_faceless_effect = true
    elif flag == "indestructible":
     indestructible = true
    elif flag == "face_status":
     face_status = true
    elif flag == "faceless":
     faceless = true
    elif flag == "override_default_title":
     override_default_title = true
    elif flag == "destroy_on_turn_end":
     destroy_on_turn_end = true
    elif flag == "prevents_falling":
     prevents_falling = true
    elif flag == "spray_exempt":
     spray_exempt = true
    elif flag == "spray_destroys":
     spray_destroys = true
    elif flag == "space":
     space = true
    elif flag == "type_unique_status":
     type_unique_status = true
    elif flag.begins_with("priority_") and flag.trim_prefix("priority_").is_valid_int():
     priority = flag.trim_prefix("priority_").to_int()
    else:
     assert (false, "Invalid status flag " + flag + " for status " + id)

 if priority == INT64_MIN:
  if is_exclusive:
   priority = 50
  else:
   priority = 0

 has_process = has_method(&"_process")
 _status_init()


func _status_init() -> void :
 pass


func connect_tile(parent, data, from_save = false):
 tile = parent
 tile.updated.connect(_on_tile_updated)

 _status_connect()

 update_visuals()

 if from_save:
  load_save_data(data)
 else:
  apply(data)


func _status_connect() -> void :
 pass


func clear():
 pass


func get_sprite_animation():
 return "default"


func update_frame() -> void :
 var frame = Globals.TileStatusFrame[id]
 tile.tile_sprite.set_frame(frame)


func update_visuals():
 if id not in Globals.TileStatusFrame:
  return

 update_frame()

 var sprite_animation = get_sprite_animation()
 if sprite_animation == null:
  return
 tile.sprite_anim_player.play(sprite_animation)

 tile.sprite_anim_player.seek(fmod(Time.get_ticks_msec() / 1000.0, tile.sprite_anim_player.current_animation_length))


func get_tooltip_context():
 return {status_value = get_status_value()}


func update():
 update_visuals()


func play_tile_sound(base_pitch: float = 1.0, bus: String = "Sound") -> void :
 if id in Sounds.STATUS_SOUNDS:
  AudioManager.play_sound(Sounds.STATUS_SOUNDS[id], base_pitch, 1.0, bus)


func tile_exists(allow_projectile = false):
 return tile != null and not tile.is_removing() and (allow_projectile or not tile.is_projectile)


func invalidates_word():
 return false


func handles_click() -> bool:
 return false


func handle_click() -> bool:
 return true


func preventing_dragging() -> bool:
 return false


func will_destroy_on_turn_end() -> bool:
 return destroy_on_turn_end


func preventing_falling() -> bool:
 return prevents_falling


func is_faceless() -> bool:
 return faceless


func is_always_playable() -> bool:
 return false


func is_relevant() -> bool:
 if no_faceless_effect and tile.has_faceless_status():
  return false

 return true


func get_priority() -> int:
 return priority


func is_space() -> bool:
 return space


func is_spray_exempt() -> bool:
 return spray_exempt


func destroyed_by_spray() -> bool:
 return spray_destroys



func apply(_data):
 pass


func get_status_value() -> int:
 return max(1, tile.get_value()) + Game.balance.status_added_value


func _on_tile_updated():
 if not tile_exists(true):
  return

 update()



func get_save_data():
 return null



func load_save_data(_save):
 pass
