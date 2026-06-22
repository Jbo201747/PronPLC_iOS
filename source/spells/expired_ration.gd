extends Spell


enum Effects{
 WILDCARD, 
 SLASHED, 
 NUMBER, 
 SUIT, 
 OTHER_SUIT, 
 N_GRAM, 
}

const SPECIAL_FACE_GROUPS = [
 [
  Effects.WILDCARD, 
  Effects.SLASHED, 
  Effects.NUMBER, 
  Effects.NUMBER, 
  Effects.N_GRAM, 
 ], 
 [
  Effects.SUIT, 
  Effects.SUIT, 
  Effects.SLASHED, 
  Effects.NUMBER, 
  Effects.N_GRAM, 
 ], 
 [
  Effects.SUIT, 
  Effects.SUIT, 
  Effects.OTHER_SUIT, 
  Effects.OTHER_SUIT, 
  Effects.N_GRAM, 
 ], 
 [
  Effects.WILDCARD, 
  Effects.SLASHED, 
  Effects.SLASHED, 
  Effects.SLASHED, 
  Effects.N_GRAM, 
 ], 
 [
  Effects.WILDCARD, 
  Effects.NUMBER, 
  Effects.NUMBER, 
  Effects.NUMBER, 
  Effects.N_GRAM, 
 ], 
 [
  Effects.WILDCARD, 
  Effects.WILDCARD, 
  Effects.NUMBER, 
  Effects.N_GRAM, 
  Effects.N_GRAM, 
 ], 
]


func set_status_tooltips() -> void :
 status_tooltips = [TileStatus.GUNK]


func _use() -> void :
 var target_tiles = get_tiles({
  amount = 5, 
  effect_priority = NONPOSITIVE_EFFECT_PRIORITY, 
  exclude_effects = [TileStatus.GUNK], 
  exclude_rows = [0], 
  has_face = true, 
 })

 var fallback_tiles = get_tiles({
  amount = 5 - target_tiles.size(), 
  effect_priority = NONPOSITIVE_EFFECT_PRIORITY, 
  exclude_effects = [TileStatus.GUNK], 
  has_face = true, 
 })

 target_tiles += fallback_tiles

 if target_tiles.is_empty():
  _end_use()
  return

 var special_faces = rng.spell.pick_random(SPECIAL_FACE_GROUPS).duplicate()
 var suits = Letters.SUITS.duplicate()

 rng.spell.shuffle(special_faces)
 rng.spell.shuffle(suits)

 var suit = suits.pop_front()
 var other_suit = suits.pop_front()

 AudioManager.play_sound(Sounds.SPELLS.SODA_CAN)

 for tile in target_tiles:
  var special_face = special_faces.pop_front()

  tile.add_status(TileStatus.GUNK)
  apply_special_face(tile, special_face, suit, other_suit)

  tile.add_poofcloud(tile.get_color())
  AudioManager.play_sound(Sounds.STATUS_SOUNDS[TileStatus.GUNK])

  await Game.timeout(0.08)

 _post_use()


func apply_special_face(tile: Tile, special_face: int, suit: String, other_suit: String) -> void :
 if special_face == Effects.WILDCARD:
  tile.set_face("*")

 elif special_face == Effects.SLASHED:
  tile.randomize_face([], rng.spell)
  tile.apply_slashed(rng.spell)

 elif special_face == Effects.NUMBER:
  var number = rng.spell.pick_random(Letters.NUMPAD_CHARACTERS.keys())
  tile.set_face(number)

 elif special_face == Effects.SUIT:
  tile.set_face(suit)

 elif special_face == Effects.OTHER_SUIT:
  tile.set_face(other_suit)

 elif special_face == Effects.N_GRAM:
  if rng.spell.randi_range(0, 1) == 0:
   var bigram: = Letters.get_random_bigram(null, rng.spell)
   tile.set_face(bigram)
  else:
   var trigram: = Letters.get_random_trigram(rng.spell)
   tile.set_face(trigram)
