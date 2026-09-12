## Layout is separate from the lesson state machine.
class_name LessonLayout
extends RefCounted


static func build(scene: Control) -> void:
    scene.set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("#2a2633")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    scene.add_child(bg)

    scene.board_view = GoBoardView.new()
    scene.board_view.position = Vector2(6, 8)
    scene.board_view.size = Vector2(192, 192)
    scene.board_view.point_activated.connect(scene._on_point)
    scene.add_child(scene.board_view)
    scene._navigation = BoardNavigation.new()
    scene._navigation.position = Vector2(6, 200)
    scene._navigation.size = Vector2(192, 16)
    scene.add_child(scene._navigation)
    scene._navigation.setup(scene.board_view)
    scene._actions = MouseActions.new()
    scene._actions.position = Vector2(204, 197)
    scene.add_child(scene._actions)
    scene._actions.action_selected.connect(scene._mouse_action)

    var panel := NinePatchRect.new()
    panel.texture = load("res://art/rendered/ui/panel.png")
    for m in ["left", "top", "right", "bottom"]:
        panel.set("patch_margin_%s" % m, 6)
    panel.position = Vector2(202, 8)
    panel.size = Vector2(176, 158)
    panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    scene.add_child(panel)

    # Two lines for the title. "You May Not Take It Straight Back" wrapped and
    # landed on top of the step counter; a title is written for the lesson, not
    # measured against a panel, so the panel gives it the room.
    scene._title = _label(panel, Vector2(10, 8), 156, 9, "#8a6023", 22)
    scene._title.text = scene.lesson.title
    scene._progress = _label(panel, Vector2(10, 30), 156, 9, "#6b6577")
    scene._instruction = _label(panel, Vector2(10, 44), 156, 9, "#14121a", 52)
    scene._message = _label(panel, Vector2(10, 98), 156, 9, "#367f72", 52)
    scene._hints = _label(scene, Vector2(204, 172), 176, 9, "#8a8494", 40)
    scene._hints.text = "Click / Space: play"

    scene._overlay = Control.new()
    scene._overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    scene._overlay.visible = false
    scene.add_child(scene._overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    scene._overlay.add_child(dim)
    scene._card = UiKit.panel(scene._overlay, Rect2(36, 46, 312, 124))
    scene._overlay_text = UiKit.label(scene._card, Vector2(10, 10), 292, UiKit.INK, 104)
    scene._modal_actions = MouseActions.new()
    scene._modal_actions.position = Vector2(138, 197)
    scene._overlay.add_child(scene._modal_actions)
    scene._modal_actions.configure([["Continue", "interact"]])
    scene._modal_actions.action_selected.connect(scene._mouse_action)


static func _label(parent: Node, pos: Vector2, width: int, font_size: int, colour: String,
        height: int = 0) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, height if height > 0 else font_size + 6)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color(colour))
    parent.add_child(l)
    return l
