shader_type canvas_item;
render_mode unshaded;
uniform sampler2D depth_map : filter_nearest, repeat_disable;
uniform vec2 room_size;
uniform float actor_depth;
varying vec2 room_pixel;
void vertex() {
    room_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
    // Fragment COLOR already contains the texture; sampling twice darkens skin and cloth.
    vec4 colour = COLOR;
    vec2 room_uv = room_pixel / room_size;
    float surface_depth = texture(depth_map, room_uv).r;
    // Half a logical pixel avoids contact-edge flicker without hiding the toes.
    if (all(greaterThanEqual(room_uv, vec2(0.0))) && all(lessThanEqual(room_uv, vec2(1.0)))
        && surface_depth > actor_depth + 0.001) colour.a = 0.0;
    COLOR = colour;
}
