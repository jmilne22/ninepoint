shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
void vertex() { VERTEX += NORMAL * 0.0055; }
void fragment() { ALBEDO = vec3(0.034, 0.027, 0.024); }
