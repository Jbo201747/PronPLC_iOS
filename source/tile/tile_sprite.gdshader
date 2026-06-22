shader_type canvas_item;

instance uniform bool hole_enabled;
instance uniform vec2 hole_local_position;
uniform sampler2D hole_mask : filter_nearest;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (hole_enabled) {
		vec2 hole_size = vec2(textureSize(hole_mask, 0));
		vec2 position_in_hole = local_position - hole_local_position;
		if (
			position_in_hole.x >= 0.0 && 
			position_in_hole.y >= 0.0 &&
			position_in_hole.x <= hole_size.x &&
			position_in_hole.y <= hole_size.y
		) {
			vec2 hole_uv = position_in_hole / hole_size;
			if (texture(hole_mask, hole_uv).a != 0.0) discard;
		}
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
