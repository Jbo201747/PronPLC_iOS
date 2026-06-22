shader_type canvas_item;

instance uniform vec4 recolor;

void fragment() {
	if (texture(TEXTURE, UV).a > 0.001) {
		COLOR = recolor;
	}
}