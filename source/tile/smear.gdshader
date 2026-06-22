shader_type canvas_item;

uniform sampler2D noise;

void fragment() {
	vec4 noise_data = texture(noise, UV);
	float intensity = 1.0 - abs(0.5 - UV.y) * 4.0;
	float offset = (noise_data.r - 0.5) * 50.0 * TEXTURE_PIXEL_SIZE.x * intensity;
	vec4 texture_data = texture(TEXTURE, UV + vec2(offset, 0.0));
	COLOR = texture_data;
}
