@tool
class_name StringKeyRichLabel extends RichTextLabel


@export var key: String = "":
 set(value):
  key = value
  _update_text()


func _notification(what: int) -> void :
 if what == NOTIFICATION_EDITOR_PRE_SAVE:
  text = ""
 elif what == NOTIFICATION_EDITOR_POST_SAVE:
  _update_text()


func _update_text() -> void :
 if StringManager.has_string(key):
  text = StringManager.get_string(key)
 else:
  text = key
