shader_type spatial;
render_mode specular_disabled;
uniform vec4 colour : source_color = vec4(1.0);
uniform bool wood = false;
uniform bool leaf = false;
uniform bool water = false;
uniform bool washer = false;
uniform bool metal = false;
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
    if (water) ALBEDO+=vec3(.008,.018,.018)*sin(world_position.x*7.0+world_position.z*4.0+TIME*.65);
    if (washer) ALBEDO*=.94+.06*sin(world_position.x*17.0+world_position.y*19.0+TIME*3.0);
    ROUGHNESS=metal ? .48 : .86;

}
