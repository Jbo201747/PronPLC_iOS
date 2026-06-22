extends Status


func apply(_data):
 tile.tile_sprite.bruise_mask.show()
 tile.tile_sprite.bruise_mask.frame = randi_range(0, 2)


func clear():
 tile.tile_sprite.bruise_mask.hide()


func get_save_data():
 return tile.tile_sprite.bruise_mask.frame


func load_save_data(frame):
 tile.tile_sprite.bruise_mask.show()
 tile.tile_sprite.bruise_mask.frame = frame
