shader_type canvas_item;


uniform float frequency = 0.01;
uniform float height = 16.0;
uniform float amplitude = 8.0;
uniform vec2 sprite_scale = vec2(0.25);
uniform bool pixel_snap = false;
uniform sampler2D dark_room: filter_nearest;


void fragment() {
	if (COLOR == vec4(1.0)) {
		vec2 use_uv = UV;

		if (pixel_snap) {
			vec2 snapped_uv = UV - mod(UV, TEXTURE_PIXEL_SIZE / sprite_scale);
			use_uv = snapped_uv;
		}

		float offset = TAU * (((use_uv.y / TEXTURE_PIXEL_SIZE.y) * sprite_scale.y) / height);
		float x_offset = sin(TIME * frequency * TAU + offset) * (amplitude / sprite_scale.x);
		COLOR = texture(dark_room, use_uv + vec2(x_offset * TEXTURE_PIXEL_SIZE.x, 0.0));
	}
}