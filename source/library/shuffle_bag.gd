class_name ShuffleBag

var rng: RNG
var list_source: Variant
var bag: Array = []
var extend_bag: Array = []


func _init(init_list_source: Variant, init_rng: RNG = null):
 list_source = init_list_source
 rng = init_rng


func set_rng(value: RNG) -> void :
 rng = value


func fill():
 if list_source is Array:
  bag = list_source.duplicate()
 elif list_source is Callable:
  bag = list_source.call()

 bag.append_array(extend_bag)
 extend_bag = []

 rng.shuffle(bag)


func pop(exclude: Array = []) -> Variant:
 while true:
  if bag.is_empty():
   fill()

  var has_non_excluded
  for entry in bag:
   if entry not in exclude:
    has_non_excluded = true
    break

  var front = bag.pop_front()
  if front in exclude:
   if has_non_excluded:
    bag.append(front)
   else:
    extend_bag.append(front)
  else:
   return front

 return null


func remove_from_bag(value: Variant) -> void :
 if value in bag:
  bag.erase(value)


func get_save_data() -> Dictionary:
 return {
  bag = bag, 
  extend_bag = extend_bag, 
  rng = rng.get_save_data(), 
 }


func load_save_data(save: Dictionary) -> void :
 bag = save.bag
 extend_bag = save.extend_bag

 if rng == null:
  rng = RNG.new()

 rng.load_save_data(save.rng)
