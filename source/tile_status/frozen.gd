extends Status


func apply(_data):
 tile.icicles.show()
 tile.icicles.frame = randi_range(0, 2)


func clear():
 tile.icicles.hide()


func get_save_data():
 return tile.icicles.frame


func load_save_data(frame):
 tile.icicles.show()
 tile.icicles.frame = frame
