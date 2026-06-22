shader_type canvas_item;

instance uniform bool hole_enabled;
instance uniform vec2 hole_offset;
uniform vec2 viewport_scale;
uniform sampler2D hole_mask : filter_nearest;

void fragment() {
	if (hole_enabled) {
		vec2 hole_size = TEXTURE_PIXEL_SIZE * 8.0 * viewport_scale;
		vec2 hole_tl = vec2(0.5, 0.5) + (hole_offset * TEXTURE_PIXEL_SIZE * viewport_scale) - hole_size / 2.0;
		vec2 hole_br = hole_tl + hole_size;

		if (UV.x > hole_tl.x && UV.y > hole_tl.y && UV.x < hole_br.x && UV.y < hole_br.y) {
			vec2 hole_uv = (UV - hole_tl) / hole_size;
			vec4 mask_color = texture(hole_mask, hole_uv);
			if (mask_color.a > 0.0) {
				COLOR.a = 0.0;
			}
		}
	}
}
