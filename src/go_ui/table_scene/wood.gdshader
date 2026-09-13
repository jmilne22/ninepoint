shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0);
varying vec3 location;
void vertex() { location = VERTEX; }
void fragment() {
    vec2 uv = location.xz * vec2(1.2, 0.8) + 0.5;
    ALBEDO = texture(grain, uv).rgb * tint;
    ROUGHNESS = 0.68;
    SPECULAR = 0.28;
}
