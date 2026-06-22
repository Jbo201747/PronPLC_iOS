extends TileModifierSpell


enum {
 STORE, 
 PLACE, 
}

var state = STORE


func _ready() -> void :
 update_state()


func get_tooltip_context():
 return {store = state == STORE}


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 if state == STORE:
  await store_tile(real_tile)
 elif state == PLACE:
  place_tile(tile, is_preview)

 update_state()


func is_tile_selectable(tile):
 if state == STORE:
  return true
 elif state == PLACE:
  return not tile.has_harmful_status()


func can_use_while_building():
 return state == PLACE


func has_special_tile_tooltip():
 return state == PLACE


func store_tile(tile):
 SaveManager.get_save_data().fingernail_tile = tile.get_save_data()
 await tile_board.remove_tile(tile, {
  poof_color = Globals.COLORS.SMOKE, 
  ignore_status = true, 
 })


func place_tile(tile, is_preview):
 tile.load_save_data(SaveManager.get_save_data().fingernail_tile)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.SMOKE)
  SaveManager.get_save_data().erase("fingernail_tile")


func update_state():
 if "fingernail_tile" in SaveManager.get_save_data():
  state = PLACE
 else:
  state = STORE

 description_updated.emit()


func post_generate_tooltip(tooltip):
 if state == PLACE:
  var preview_tile = tile_board.create_preview_tile()
  preview_tile.load_save_data(SaveManager.get_save_data().fingernail_tile)

  tooltip.add_subtooltip(
   StringManager.get_string("spell/" + id + "/stored_preview_title"), 
   "", 
   preview_tile, 
  )
