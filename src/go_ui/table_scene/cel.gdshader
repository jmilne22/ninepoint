shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 colour : source_color = vec4(1.0);
varying vec3 normal_world;
void vertex() { normal_world = MODEL_NORMAL_MATRIX * NORMAL; }
void fragment() {
    float sun = dot(normalize(normal_world), normalize(vec3(-0.5, 0.7, 0.9)));
    float tone = mix(0.70, 1.0, smoothstep(-0.20, 0.55, sun));
    ALBEDO = colour.rgb * tone;
}
