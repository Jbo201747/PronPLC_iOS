@tool
class_name VoiceCredits extends MarginContainer


@export var is_shadow: bool = false:
 set(value):
  is_shadow = value
  for child in find_children("VoiceCreditSprite*"):
   child.shadow = is_shadow
