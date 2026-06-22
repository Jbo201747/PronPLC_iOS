shader_type canvas_item;

uniform vec2 mask_world_position;
uniform vec2 mask_size;
uniform sampler2D mask;

varying vec2 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
}


void fragment() {
	vec2 position_in_mask = world_position - mask_world_position;
	if (position_in_mask.x < 0.0 || position_in_mask.y < 0.0 || position_in_mask.x > mask_size.x || position_in_mask.y > mask_size.y) {
		discard;
	} else {
		//COLOR = vec4(position_in_mask.x / mask_size.x, position_in_mask.y / mask_size.y, 0.0, 1.0);
		vec4 mask_color = texture(mask, position_in_mask / mask_size);
		if (mask_color.a == 0.0) {
			discard;
		}
	}
}