shader_type canvas_item;
render_mode unshaded;
uniform sampler2D material_map : filter_nearest, repeat_disable;
void fragment() {
    // Fragment COLOR already contains the texture; sampling twice darkens skin and cloth.
    vec4 colour = COLOR;
    vec3 mask = texture(material_map, UV).rgb;
    if (mask.g > 0.9) {
        float ripple = floor(sin(UV.x * 390.0 + UV.y * 170.0 + TIME * 1.2) * 2.0) / 2.0;
        colour.rgb += vec3(0.022, 0.028, 0.025) * ripple;
    }
    if (mask.b > 0.9) {
        float drum = sin(TIME * 3.0 + UV.x * 140.0 + UV.y * 100.0);
        colour.rgb += vec3(0.025, 0.035, 0.038) * drum;
    }
    COLOR = colour;
}
