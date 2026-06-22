class_name DifficultySelectorIcon extends SelectorIcon


var difficulty: int = 0
var character: String = ""
var adjusted_size: = false

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var icon: DifficultyIcon = %DifficultyIcon


func init_select_state(selected: bool) -> void :
 icon.set_difficulty(difficulty)

 var is_hazel_unlocked: = Globals.is_difficulty_unlocked(10, character)

 if difficulty == 10:
  visible = is_hazel_unlocked
  if not visible:
   return

 if (
   (difficulty == 0
   or ( not is_hazel_unlocked and difficulty == 9)
   or (is_hazel_unlocked and difficulty == 10))
   and not adjusted_size
 ):
  adjusted_size = true
  button.custom_minimum_size.x += 4
  if difficulty == 0:
   button.position.x -= 4

 anim.play_advance("RESET")
 if selected:
  return
 elif is_selectable():
  anim.play_advance("unlocked")
 else:
  icon.set_difficulty(11)
  anim.play_advance("locked")


func nudge() -> void :
 anim.play("nudge")


func select() -> void :
 anim.play("select")


func deselect() -> void :
 if is_selectable():
  anim.play("deselect")
 else:
  anim.play("deselect_locked")


func select_failed() -> void :
 pass


func is_selectable() -> bool:
 return Globals.is_difficulty_unlocked(difficulty, character)
