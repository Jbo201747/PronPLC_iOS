@tool
extends BattleUnitSprite

signal npc_respawning
signal attack_finished

const INTENT_POSITIONS: Dictionary[int, Vector2] = {
 0: Vector2(0, -76), 
 3: Vector2(0, -88), 
 5: Vector2(0, -100), 
 7: Vector2(0, -112), 
}

@export var NPC: PackedScene = preload("res://source/enemies/sprites/npc_sprite.tscn")
@export var start_still: = false
@export var phonebook_npcs: int = 3

var npcs: Array[NPCSprite] = []
var npc_positions: Array[Vector2] = []
var phonebook_killed_timer: float = 0.0
var phonebook_respawning: = false
var chatter_playback: AudioManager.SoundPlayback

@onready var npc_markers: Dictionary[int, Node2D] = {
 3: %Markers3, 
 4: %Markers4, 
 5: %Markers5, 
 6: %Markers6, 
 7: %Markers7, 
 8: %Markers8, 
}


func _ready() -> void :
 super._ready()
 set_physics_process(false)


func _physics_process(delta: float) -> void :
 phonebook_killed_timer -= delta
 if phonebook_killed_timer <= 0.0:
  phonebook_respawn()
  set_physics_process(false)


func spawn_npcs(num_npcs: int = 0, do_respawn: = true, start_killed: int = 0) -> void :
 var is_editor: = Engine.is_editor_hint()
 if not is_editor:
  chatter_playback = play_sound(Sounds.NPC.LOOP, 1.0, 0.0)

 for npc in npcs:
  npc.queue_free()

 npcs.clear()
 npc_positions.clear()

 if do_respawn and start_still and not is_editor:
  play_sound(Sounds.NPC.TRAFFIC)

 var desync_by: float = 0.0
 var await_npcs: Array[NPCSprite] = []
 var markers: = npc_markers[num_npcs].get_children()
 for i in markers.size():
  var marker: Node2D = markers[i]
  var npc: NPCSprite = NPC.instantiate()
  add_child(npc)
  npcs.append(npc)
  npc_positions.append(marker.position)
  npc.position = marker.position
  npc.set_unit_id(unit_id)
  npc.start_respawning.connect(_on_npc_start_respawning)
  npc.state_changed.connect(_on_npc_living_state_changed)

  if i >= (num_npcs - start_killed):
   npc.is_dead = true
   npc.anim_player.play_advance("RESET")
   npc.sprite.hide()
  elif do_respawn:
   npc.is_dead = true
   await_npcs.append(npc)
   npc.respawn(start_still)
   await Game.timeout(0.4)
  else:
   npc.anim_player.play_advance("RESET")
   if start_still:
    npc.stand_still()
   else:
    npc.start_idle(desync_by)
    desync_by += 0.4

 for npc in await_npcs:
  if npc.is_dead:
   await npc.respawned


func kill_npcs(num_killed: int) -> void :
 var shuffled_npcs = get_live_npcs()
 shuffled_npcs.shuffle()

 var killed_npcs = shuffled_npcs.slice(0, num_killed)
 var hurt_npcs = shuffled_npcs.slice(num_killed)

 shuffled_npcs.shuffle()

 shit(hurt_npcs)
 ass(killed_npcs)

 await Game.timeout(2)

 await pend_npc_animations_finished("flinch", hurt_npcs)
 await pend_npc_animations_finished("fling", killed_npcs)
 await get_moving()
 await move_queue()


func shit(hurt_npcs):
 for npc in hurt_npcs:
  npc.flinch()
  await Game.timeout(0.08)


func ass(killed_npcs):
 var pitch: = 1.0
 for npc in killed_npcs:
  kill_npc(npc, pitch)
  pitch += 0.05
  await Game.timeout(0.08)


func kill_npc(npc, pitch: float = 1.0):
 play_sound(Sounds.NPC.FLINCH, pitch)

 npc.is_dead = true


 npcs.erase(npc)
 npcs.append(npc)

 npc.halt_idle()
 npc.anim_player.play("fling")

 await npc.anim_player.animation_finished

 npc.sprite.hide()


func respawn_npcs():
 var dead_npcs: = get_dead_npcs()
 for npc in dead_npcs:
  npc.respawn()
  await Game.timeout(0.4)

 for npc in dead_npcs:
  if npc.is_dead:
   await npc.respawned


func move_queue():
 var last_living_npc: int = -1
 for i in npcs.size():
  if not npcs[i].is_dead:
   last_living_npc = i

 for i in npcs.size():
  var npc = npcs[i]
  var dest = npc_positions[i]

  if npc.position == dest:
   continue

  if npc.is_dead:
   npc.position = dest
  else:
   if i == last_living_npc:
    await npc.walk_to(npc, dest, 0.5)
   else:
    npc.walk_to(npc, dest, 0.5)
    await Game.timeout(0.16)


func get_live_npcs(include_respawning: = false) -> Array[Node2D]:
 var live_npcs: Array[Node2D] = []
 for npc in npcs:
  if not npc.is_dead or (npc.is_respawning and include_respawning):
   live_npcs.append(npc)

 return live_npcs


func get_dead_npcs() -> Array[Node2D]:
 var dead_npcs: Array[Node2D] = []
 for npc in npcs:
  if npc.is_dead:
   dead_npcs.append(npc)

 return dead_npcs


func animate_attack():
 var base_pitch: float = 1.0

 var live_npcs: = get_live_npcs()
 live_npcs.shuffle()
 for npc in live_npcs:
  base_pitch += 0.05
  npc.attack(false, base_pitch)

  if npc == live_npcs[-1]:
   await npc.hit
  else:
   await Game.timeout(0.04)

 hit.emit()

 for npc in live_npcs:
  if npc.is_attacking:
   await npc.attack_finished

 attack_finished.emit()


func stand_still():
 play_sound(Sounds.NPC.TRAFFIC)

 for npc in npcs:
  npc.stand_still()

 for npc in npcs:
  await npc.anim_player.pend_animation_stopped("when_u_walkin")


func get_moving():
 var live_npcs: = get_live_npcs()
 live_npcs.shuffle()
 for npc in live_npcs:
  if not npc.is_idle:
   npc.start_idle()
   await Game.timeout(0.04)


func update_intent_position(count: int = get_live_npcs(true).size()) -> void :
 for i in range(count, -1, -1):
  if i in INTENT_POSITIONS:
   intent_marker.position = INTENT_POSITIONS[i]
   break


func pend_npc_animations_finished(anim_name, pending_npcs = npcs):
 for npc in pending_npcs:
  await npc.pend_animation_stopped(anim_name)


func pend_npc_animations(anim_name, pending_npcs = npcs):
 for npc in pending_npcs:
  await npc.pend_animation_played(anim_name)


func pend_idle_npcs(pending_npcs = npcs):
 await pend_npc_animations("when_u_walkin", pending_npcs)


func prep_phonebook_portrait() -> void :
 super.prep_phonebook_portrait()
 spawn_npcs(phonebook_npcs, false)


func prep_credits() -> void :
 super.prep_credits()
 spawn_npcs(phonebook_npcs, false)


func advance_phonebook_animation() -> void :
 if phonebook_respawning:
  return

 var live_npcs: = get_live_npcs(false)
 if live_npcs.size() > 0:
  live_npcs.shuffle()
  kill_npc(live_npcs[0])
  phonebook_killed_timer = 1.0
  set_physics_process(true)


func phonebook_respawn() -> void :
 phonebook_respawning = true
 await pend_npc_animations_finished("fling", npcs)
 await get_moving()
 await move_queue()
 await respawn_npcs()
 if start_still:
  await stand_still()
 phonebook_respawning = false


func update_chatter_volume() -> void :
 if chatter_playback == null:
  return

 var chattering_npcs: = 0
 for npc in npcs:
  if npc.is_respawning or (npc.is_idle and not npc.is_dead):
   chattering_npcs += 1

 chatter_playback.set_volume(minf(chattering_npcs, 5) / 5.0)


func _on_npc_start_respawning() -> void :
 npc_respawning.emit()


func _on_npc_living_state_changed() -> void :
 update_chatter_volume()
