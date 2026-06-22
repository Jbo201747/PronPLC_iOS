@tool
class_name RNG extends RandomNumberGenerator


func reseed(parent: RandomNumberGenerator = null) -> void :
 if parent == null:
  set_seed(randi())
 else:
  set_seed(parent.randi())


func get_seed_hex() -> String:
 return String.num_int64(seed, 16, true).lpad(8, "0")


func shuffle(array: Array) -> void :
 var shuffle_rng = RNG.new()
 shuffle_rng.reseed(self)
 for i in array.size():
  var swap_index = shuffle_rng.randi() % array.size()
  if swap_index == i:
   continue
  else:
   var swap = array[swap_index]
   array[swap_index] = array[i]
   array[i] = swap


func pick_random(array: Array[Variant]) -> Variant:
 return array[self.randi() % array.size()]


func uniform_around(base: float, max_deviation: float) -> float:
 return self.randf_range(base - max_deviation, base + max_deviation)


func random_in_rect(rect: Rect2) -> Vector2:
 return Vector2(
  self.randf_range(rect.position.x, rect.end.x), 
  self.randf_range(rect.position.y, rect.end.y), 
 )


func weighted_random(weights: Dictionary) -> Variant:
 if weights.is_empty():
  push_error("Weighted random called with empty dictionary")
  return null

 var sum_weight: float = 0.0
 for key in weights:
  sum_weight += weights[key]

 var picked_weight: = self.randf_range(0.0, sum_weight)

 var iterated_weight: = 0.0

 for key in weights:
  iterated_weight += weights[key]

  if iterated_weight >= picked_weight:
   return key

 push_error("Weighted random failed to find a key")
 return weights.keys()[-1]


func get_save_data() -> PackedInt64Array:
 return PackedInt64Array([seed, state])


func load_save_data(save: PackedInt64Array) -> void :
 set_seed(save[0])
 set_state(save[1])


static func reseed_rng_group(rng_group, rng: RNG) -> void :
 for rng_key in rng_group:
  rng_group[rng_key].reseed(rng)


static func get_rng_group_save(rng_group: Dictionary) -> Dictionary:
 var save: = {}
 for rng_key in rng_group:
  save[rng_key] = rng_group[rng_key].get_save_data()

 return save


static func load_rng_group_save(rng_group: Dictionary, save: Dictionary) -> void :
 for rng_key in save:
  if rng_key in rng_group:
   rng_group[rng_key].load_save_data(save[rng_key])
