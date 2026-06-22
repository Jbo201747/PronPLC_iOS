@tool
class_name BoardPreviewLabel extends DebossLabel


var coordinate: Vector2i = Vector2i.ZERO


func _init() -> void :
 font = preload("res://fonts/Suwannaphum-Bold.ttf")
 font_size = 9
 custom_minimum_size = Vector2(22, 20)
 color = Color("6e6b67")
 deboss_color = Color("dbd8d6")
