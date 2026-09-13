shader_type spatial;
render_mode specular_disabled;
uniform vec4 colour : source_color = vec4(1.0);
uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
uniform float grain_amount = .12;
uniform bool wood = false;
uniform bool water = false;
uniform bool washer = false;
varying vec3 world_position;
varying vec3 normal_world;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    normal_world = MODEL_NORMAL_MATRIX * NORMAL;
}
void fragment() {
    vec3 n=abs(normalize(normal_world));
    vec2 uv=n.y>.65 ? world_position.xz : (n.z>n.x ? world_position.xy : world_position.zy);
    uv*=wood ? vec2(.55,1.6) : vec2(1.4);
    float texture_tone=texture(grain,uv).r-.5;
    ALBEDO=colour.rgb*(1.0+texture_tone*grain_amount);
    if (water) {
        float ripple=sin(world_position.x*9.0+world_position.z*5.0+TIME*.8);
        ALBEDO+=vec3(.015,.025,.025)*ripple;
    }
    if (washer) ALBEDO*=.92+.08*sin(world_position.x*17.0+world_position.y*19.0+TIME*3.0);
    ROUGHNESS=1.0;
}
void light() {
    float facing=dot(NORMAL,LIGHT);
    float tone=mix(.20,.55,smoothstep(-.05,.65,facing));
    DIFFUSE_LIGHT+=tone*ATTENUATION*LIGHT_COLOR / PI;
}
