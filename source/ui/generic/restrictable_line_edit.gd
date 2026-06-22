class_name RestrictableLineEdit extends LineEdit

signal text_validated(text: String)

var regex: RegEx

@export var character_regex: String = ""
@export var validate_filename: bool = false


func _ready() -> void :
 if character_regex != "":
  regex = Util.regex(character_regex)
 text_changed.connect(_on_text_changed)
 text_submitted.connect(_on_text_submitted)


func _on_text_changed(new_text: String) -> void :
 var column: = caret_column
 var valid_text: = ""

 if character_regex != "":
  for reg_match in regex.search_all(new_text):
   valid_text += reg_match.get_string().to_upper()
 else:
  valid_text = new_text

 if validate_filename:
  valid_text = valid_text.validate_filename()

 if valid_text != new_text:
  text = valid_text
  caret_column = column

 text_validated.emit(text)


func _on_text_submitted(_new_text: String) -> void :
 release_focus()
