class_name MenuPageShadow extends ShadowCloner


func set_menu_disabled(value: bool) -> void :
 if not value:
  solid_shadow_color = Color(3298927103)
 else:
  solid_shadow_color = Color(2659090175)
