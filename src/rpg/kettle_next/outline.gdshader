shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
void vertex() { VERTEX += NORMAL * .0024; }
void fragment() { ALBEDO = vec3(.075,.055,.044); }
