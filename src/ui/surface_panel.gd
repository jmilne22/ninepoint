## Vector panel: smooth at any window scale, with one quiet border and soft shadow.
class_name SurfacePanel
extends NinePatchRect

var dark := false:
    set(value):
        dark = value
        queue_redraw()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("243e38") if dark else Color("f4eddf")
    style.border_color = Color("718a75") if dark else Color("c5b597")
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    style.shadow_color = Color(0.07,0.13,0.11,.24)
    style.shadow_size = 3
    style.shadow_offset = Vector2(0,2)
    draw_style_box(style,Rect2(Vector2.ZERO,size))
