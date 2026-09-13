shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0);
uniform bool quiet = false;
varying vec3 location;
void vertex() { location=VERTEX; }
void fragment() {
    vec2 uv=location.xz*vec2(1.2,.8)+.5;
    vec3 base=texture(grain,uv).rgb;
    float fine=sin(location.x*310.0+sin(location.z*13.0)*.65)*.008;
    float age=.985+.015*cos(location.z*12.0)*cos(location.x*5.0);
    if (quiet) { base=mix(vec3(.70,.49,.25),base,.23); fine*=.25; }
    ALBEDO=(base+fine)*tint*age;
    ROUGHNESS=.62;
    SPECULAR=.24;
}
