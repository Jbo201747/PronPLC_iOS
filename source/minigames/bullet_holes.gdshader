shader_type canvas_item;

uniform vec2 background_world_position;
uniform vec2 background_size;
uniform sampler2D holes: filter_nearest;

varying vec2 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
}

void fragment() {
	vec2 position_in_background = world_position - background_world_position;
	if (!(position_in_background.x < 0.0 || position_in_background.y < 0.0 || position_in_background.x > background_size.x || position_in_background.y > background_size.y)) {
		vec4 holes_color = texture(holes, position_in_background / background_size);
		if (holes_color == vec4(1)) {
			COLOR.a = 0.0;
		} else if (holes_color.a != 0.0) {
			COLOR = holes_color;
		}
	}
}
