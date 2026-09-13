shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D faces : source_color, filter_linear;
uniform float expression = 0.0;
uniform float gaze = 0.0;
void fragment() {
    float y=(UV.y+expression)/6.0;
    vec3 centre=texture(faces,vec2((UV.x+1.0)/3.0,y)).rgb;
    vec3 looking=texture(faces,vec2((UV.x+(gaze<0.0 ? 0.0 : 2.0))/3.0,y)).rgb;
    ALBEDO=mix(centre,looking,abs(clamp(gaze,-1.0,1.0)));
    ROUGHNESS=1.0;
}
