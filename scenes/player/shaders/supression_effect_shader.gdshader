shader_type canvas_item;

// --- Textures ---
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

// --- BASE CONTROL ---
uniform float alpha : hint_range(0.0, 1.0) = 0.6;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.2;
uniform float outer_radius : hint_range(0.0, 2.0) = 1.2;

// --- SUPPRESSION FX ---
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.2;
uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;

uniform float noise_strength : hint_range(0.0, 0.1) = 0.02;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.01;

uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;

// --- NEW BLUR CONTROL ---
// Controls how strong the blur gets at max suppression. 
// 0.0 = no blur, 0.02 = subtle, 0.05+ = very blurry/expensive
uniform float blur_strength : hint_range(0.0, 0.1) = 0.02; 

uniform float time = 0.0;


// Simple hash noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// --- RADIAL DISTANCE ---
	vec2 centered = uv - 0.5;
	float dist = length(centered);

	// --- VIGNETTE (SOFTENED) ---
	float vignette = smoothstep(inner_radius, outer_radius, dist);

	// --- PULSE EFFECT ---
	float pulse = sin(time * pulse_speed) * pulse_strength;
	vignette += pulse * (1.0 - vignette);
	
	// Clamp vignette to avoid negative values from pulse
	vignette = clamp(vignette, 0.0, 1.0);

	// --- NOISE DISTORTION ---
	float n = hash(uv * time) * noise_strength;
	vec2 distorted_uv = uv + centered * distortion_strength * n;

	// --- CHROMATIC ABERRATION & BLUR ---
	
	// Calculate blur radius based on suppression strength (vignette)
	// If vignette is 0 (center/calm), radius is 0. If 1 (edge/suppressed), radius is blur_strength.
	float current_blur_radius = vignette * blur_strength;
	
	vec3 col = vec3(0.0);
	
	if (current_blur_radius > 0.001) {
		// Perform a simple 9-tap box blur for performance
		// We sample the center and 8 surrounding points
		
		vec2 texel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
		
		// Define offsets for the 3x3 grid
		vec2 offsets[9];
		offsets[0] = vec2(-1, -1);
		offsets[1] = vec2( 0, -1);
		offsets[2] = vec2( 1, -1);
		offsets[3] = vec2(-1,  0);
		offsets[4] = vec2( 0,  0);
		offsets[5] = vec2( 1,  0);
		offsets[6] = vec2(-1,  1);
		offsets[7] = vec2( 0,  1);
		offsets[8] = vec2( 1,  1);
		
		vec3 blurred_col = vec3(0.0);
		
		for(int i = 0; i < 9; i++) {
			vec2 offset_uv = distorted_uv + (offsets[i] * current_blur_radius * texel_size);
			
			// Apply Chromatic Aberration to each tap
			vec3 tap_col;
			tap_col.r = texture(SCREEN_TEXTURE, offset_uv + vec2(chromatic_aberration, 0.0)).r;
			tap_col.g = texture(SCREEN_TEXTURE, offset_uv).g;
			tap_col.b = texture(SCREEN_TEXTURE, offset_uv - vec2(chromatic_aberration, 0.0)).b;
			
			blurred_col += tap_col;
		}
		
		col = blurred_col / 9.0;
		
	} else {
		// No blur needed, just standard chromatic aberration
		col.r = texture(SCREEN_TEXTURE, distorted_uv + vec2(chromatic_aberration, 0.0)).r;
		col.g = texture(SCREEN_TEXTURE, distorted_uv).g;
		col.b = texture(SCREEN_TEXTURE, distorted_uv - vec2(chromatic_aberration, 0.0)).b;
	}

	// --- FINAL MIX ---
	float final_alpha = vignette * alpha;

	// Instead of pure black, blend with scene
	vec3 darken = mix(col, vec3(0.0), final_alpha * 0.7);

	COLOR = vec4(darken, 1.0);
}