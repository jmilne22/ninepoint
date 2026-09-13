shader_type spatial;
render_mode specular_disabled;
uniform vec4 colour : source_color = vec4(1.0);
uniform bool wood = false;
uniform bool leaf = false;
uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
varying vec3 normal_world;
void vertex() {
    world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    if (leaf) VERTEX.x += .012*sin(TIME*.85+world_position.x*2.3+world_position.z)*smoothstep(.3,1.4,world_position.y);
    normal_world=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
    vec3 n=abs(normalize(normal_world));
    vec2 uv=n.y>.65 ? world_position.xz : (n.z>n.x ? world_position.xy : world_position.zy);
    float tone=texture(grain,uv*(wood ? vec2(.48,1.2) : vec2(.7))).r-.5;
    ALBEDO=colour.rgb*(1.0+tone*(wood ? .25 : .10));
    ROUGHNESS=.86;
}
void light() {
    float facing=dot(NORMAL,LIGHT);
    float shade=mix(.12,.82,smoothstep(-.18,.8,facing));
    DIFFUSE_LIGHT+=shade*ATTENUATION*LIGHT_COLOR/PI;
}
