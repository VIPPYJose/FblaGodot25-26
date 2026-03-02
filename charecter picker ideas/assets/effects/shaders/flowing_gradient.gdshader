shader_type canvas_item;

// Gradient texture - use a GradientTexture2D or GradientTexture for unlimited colors
uniform sampler2D gradient_texture : hint_default_white, filter_linear;

// How many color bands (lower = more pixelated, higher = smoother)
uniform float pixel_steps : hint_range(2.0, 256.0) = 100;

// Animation speed (positive = forward, negative = reverse)
uniform float speed : hint_range(-2.0, 2.0) = 0.1;

// Gradient flow direction (normalized automatically)
uniform vec2 direction = vec2(1.0, 0.0);

void fragment() {
	vec2 uv = UV;
	
	// Project UV onto direction and add time-based offset for flowing effect
	vec2 dir = length(direction) > 0.001 ? normalize(direction) : vec2(1.0, 0.0);
	float gradient_pos = dot(uv, dir) + TIME * speed;
	
	// Wrap for seamless repeating
	gradient_pos = fract(gradient_pos);
	
	// Pixelation: quantize into discrete bands when pixel_steps is low; smooth when high
	float sample_pos = pixel_steps < 128.0 ? floor(gradient_pos * pixel_steps) / pixel_steps : gradient_pos;
	
	// Sample gradient - horizontal axis is the gradient ramp
	vec4 color = texture(gradient_texture, vec2(sample_pos, 0.5));
	COLOR = color;
}
