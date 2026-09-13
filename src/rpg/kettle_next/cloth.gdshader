shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 colour : source_color = vec4(1.0);
uniform bool fabric = false;
varying vec3 normal_world;
varying vec3 local_position;
void vertex() {
    normal_world = MODEL_NORMAL_MATRIX * NORMAL;
    local_position = VERTEX;
}
void fragment() {
    vec3 n=normalize(normal_world);
    float key=dot(n,normalize(vec3(-.5,.8,.65)));
    float shade=mix(.64,1.02,smoothstep(-.35,.7,key));
    float weave=fabric ? .006*sin(local_position.y*390.0)*sin(local_position.x*360.0) : 0.0;
    vec3 shadow_tint=mix(vec3(.86,.94,1.02),vec3(1.0),smoothstep(-.3,.5,key));
    ALBEDO=colour.rgb*shadow_tint*(shade+weave);
}
