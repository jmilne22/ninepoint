## Render each 3D surface at the pixel size occupied by its existing 2D layout.
class_name NativeViewportSize
extends Node

var view: SubViewport
var display: CanvasItem
var logical_extent := Vector2.ZERO

static func bind_view(target: SubViewport, item: CanvasItem, extent := Vector2.ZERO) -> void:
    var sizing := NativeViewportSize.new()
    sizing.view = target
    sizing.display = item
    sizing.logical_extent = extent
    sizing.process_mode = Node.PROCESS_MODE_ALWAYS
    target.add_child(sizing)
    sizing.refresh()

func _process(_delta: float) -> void:
    refresh()

func refresh() -> void:
    if not display.is_inside_tree(): return
    var extent := (display as Control).size if display is Control else logical_extent
    # Includes letterboxing and nested Control scales, not the window's unused bars.
    # CanvasItem.get_screen_transform() alone omits the root's stretch here.
    var transform := display.get_viewport().get_final_transform() * display.get_global_transform_with_canvas()
    var pixels := Vector2i(maxi(2, roundi(extent.x * transform.x.length())),
        maxi(2, roundi(extent.y * transform.y.length())))
    if view.size != pixels:
        view.size = pixels
