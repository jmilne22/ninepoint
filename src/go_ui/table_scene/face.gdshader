shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D faces : source_color, filter_linear;
uniform float expression = 0.0;
void fragment() {
    ALBEDO = texture(faces, vec2(UV.x, (UV.y + expression) / 6.0)).rgb;
    ROUGHNESS = 1.0;
}
