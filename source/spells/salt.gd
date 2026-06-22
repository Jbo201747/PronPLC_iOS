extends Spell


const TIMESCALE_BOOST = 1
var apply_number = false

var spell_charge_decay: = SpellChargeDecay.new(self, 10)


func _ready() -> void :
 if main.is_player_turn and is_owned() and not spell_charge_decay.timer.is_running():
  spell_charge_decay.timer.start()


func _process(delta: float) -> void :
 spell_charge_decay._process(delta)


func _use():
 var remaining_seconds = int(main.turn_timer.get_remaining_time() / 1000)
 var apply_curse: bool = false
 var type_priority = TileType.DEFENSE
 if has_curse(CURSE.CURSED) and remaining_seconds % 10 == 0:
  apply_curse = true
  type_priority = null
 elif remaining_seconds % 2 == 0:
  type_priority = TileType.DAMAGE

 var apply_bomb = get_tiles({
  amount = 1, 
  effect_priority = STATUS_EFFECT_PRIORITY, 
  type_priority = type_priority, 
 })

 if apply_bomb.is_empty():
  _end_use()
  return

 for tile: Tile in apply_bomb:
  if apply_number and not tile.has_any_effect(Globals.FULL_WILDCARD_EFFECTS + [TileEffect.NUMBER]):
   tile.set_face(Letters.get_keypad_number(tile.face, rng.spell))

  if apply_curse:
   tile.add_status(TileStatus.CURSED)
  else:
   tile.add_status(TileStatus.BOMB, 1)
  tile.add_poofcloud(Globals.COLORS.SMOKE)

 main.turn_timer.time_scale += TIMESCALE_BOOST
 AudioManager.play_sound(Sounds.SPELLS.SALT)

 play_audio_effect(apply_curse)

 _post_use()


func play_audio_effect(evil: bool) -> void :
 if evil:
  AudioManager.effects.salt_evil_a.set_enabled(true, 0.3, 0.3, 1.3)
  await Game.timeout(0.3)
  AudioManager.effects.salt_evil_b.set_enabled(true, 0.3, 0.3, 0.3)
 else:
  AudioManager.effects.salt.set_enabled(true, 0.3, 0.3, 1.3)


func generate_player_spell_base_tooltip(tooltip: GameTooltip) -> void :
 var damage_preview_tile: = tile_board.create_preview_tile()
 damage_preview_tile.tile_face.force_no_value = true
 damage_preview_tile.set_face("Even")

 var defense_preview_tile: = tile_board.create_preview_tile()
 defense_preview_tile.tile_face.force_no_value = true
 defense_preview_tile.set_face("Odd")
 defense_preview_tile.set_type(TileType.DEFENSE)

 var preview_tiles: Array[Tile] = [damage_preview_tile, defense_preview_tile]
 if has_curse(CURSE.CURSED):
  var curse_preview_tile: = tile_board.create_preview_tile()
  curse_preview_tile.tile_face.force_no_value = true
  curse_preview_tile.set_face("Zero")
  curse_preview_tile.add_status(TileStatus.CURSED)
  preview_tiles.append(curse_preview_tile)

 tooltip.add_subtooltip(get_title(), get_description(), preview_tiles)
