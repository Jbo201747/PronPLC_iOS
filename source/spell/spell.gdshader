shader_type canvas_item;

instance uniform ivec4 frame_data;
instance uniform bool outline_active;
instance uniform vec4 outline_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

instance uniform vec4 recolor: source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform vec4 recolor_dark: source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform bool recolor_active;
instance uniform bool recolor_dark_active;
instance uniform float recolor_brightness = 0.0;
instance uniform float recolor_contrast = 1.0;

instance uniform bool sepia_active = false;

instance uniform bool hsv_active = false;
instance uniform float hue_offset = 0.0;
instance uniform float saturation_offset = 0.0;

varying vec4 vertex_color;

const mat3 sepia = mat3(
	vec3(.393, .769, .189),
	vec3(.349, .686, .168),
	vec3(.272, .534, .131)
);

const vec3 grayscale_luminosity = vec3(0.2126, 0.7152, 0.0722);

vec3 hsv_to_rgb(vec3 color) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(color.xxx + K.xyz) * 6.0 - K.www);
	return color.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}

vec3 rgb_to_hsv(vec3 color) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(color.bg, K.wz), vec4(color.gb, K.xy), step(color.b, color.g));
	vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_adjustment(vec3 col, float hue_off, float sat_offset, float val_offset) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(col.bg, K.wz), vec4(col.gb, K.xy), step(col.b, col.g));
	vec4 q = mix(vec4(p.xyw, col.r), vec4(col.r, p.yzx), step(p.x, col.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	vec3 hsv = vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	hsv.x += hue_off / 360.0;
	hsv.y += sat_offset;
	hsv.z += val_offset;
	return hsv;
}

bool pixel_counts(sampler2D tex, ivec2 pixel) {
	if (pixel.x < frame_data.x || pixel.y < frame_data.y || pixel.x >= frame_data.x + frame_data.z || pixel.y >= frame_data.y + frame_data.w) {
		return false;
	}

	return texelFetch(tex, pixel, 0).a > 0.0001;
}

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	if (COLOR.a > 0.0001 && (COLOR.r > 0.0001 || COLOR.g > 0.0001 || COLOR.b > 0.0001)) {
		if (recolor_active || sepia_active || hsv_active) {
			COLOR.rgb /= vertex_color.rgb;
		}
		
		if (hsv_active) {
			vec3 offset_hsv = hsv_adjustment(COLOR.rgb, hue_offset, saturation_offset, 0.0);
			COLOR.rgb = hsv_to_rgb(offset_hsv);
		}
		
		if (recolor_active) {
			//float grayscale = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
			float grayscale_linear = dot(COLOR.rgb, grayscale_luminosity);
			float grayscale = 1.0;
			if (grayscale_linear <= 0.0031308) {
				grayscale = grayscale_linear * 12.92;
			} else {
				grayscale = 1.055 * pow(grayscale_linear, 1.0 / 2.4) - 0.055;
			}
			vec4 use_recolor = recolor;
			if (recolor_dark_active) {
				use_recolor = mix(recolor_dark, recolor, grayscale);
				
				use_recolor -= recolor_dark;
				use_recolor -= (recolor - recolor_dark) / 2.0;
				use_recolor *= recolor_contrast;
				use_recolor += ((recolor - recolor_dark) / 2.0) + recolor_dark;
			}
			
			COLOR.rgb = grayscale * use_recolor.rgb;
			COLOR.rgb += vec3(recolor_brightness);
		}
		
		if (sepia_active) {
			COLOR.rgb *= sepia;
			COLOR.rgb = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
		}
		
		if (recolor_active || sepia_active) {
			COLOR.rgb *= vertex_color.rgb;
		}
	} else if (COLOR.a < 0.0001) {
		if (outline_active) {
			ivec2 pixel = ivec2(floor(UV / TEXTURE_PIXEL_SIZE));
			if (pixel_counts(TEXTURE, pixel + ivec2(0, 1))) {
				COLOR = outline_color;
			} else if (pixel_counts(TEXTURE, pixel + ivec2(0, -1))) {
				COLOR = outline_color;
			} else if (pixel_counts(TEXTURE, pixel + ivec2(1, 0))) {
				COLOR = outline_color;
			} else if (pixel_counts(TEXTURE, pixel + ivec2(-1, 0))) {
				COLOR = outline_color;
			}
		}
	}
}
