shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform float offset = 0.0;
void vertex() {
    VERTEX.x += sin(TIME*1.2+VERTEX.y*14.0+offset)*.012;
}
void fragment() {
    float side=pow(max(0.0,1.0-abs(UV.x-.5)*2.0),3.0);
    float fade=sin(UV.y*3.14159);
    ALBEDO=vec3(.89,.88,.81);
    ALPHA=side*fade*.13*(.65+.35*sin(TIME*.8+offset));
}
