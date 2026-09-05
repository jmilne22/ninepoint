class_name HandicapHelp
extends Control

signal closed

var request: MatchRequest
var setup: GoMatchSetup
var first_time := true
var _pages: PackedStringArray
var _page := 0
var _body: Label
var _footer: Label
var _reason := false
var _reason_page := 0
var _reason_pages: PackedStringArray


func _ready() -> void:
    name = "HandicapHelp"
    z_index = 80
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := UiKit.panel(self, Rect2(202, 4, 178, 208))
    UiKit.label(panel, Vector2(10, 8), 158, UiKit.GOLD).text = "HANDICAP STONES"
    _body = UiKit.label(panel, Vector2(10, 27), 158, UiKit.INK, 143)
    _footer = UiKit.label(panel, Vector2(10, 175), 158, UiKit.INK_SOFT, 26)
    _pages = MatchPresentation.handicap_pages(request, setup)
    _reason_pages = UiKit.paginate(MatchPresentation.handicap_reason(request, setup), 158, 143)
    if not first_time:
        _pages = PackedStringArray(["%s starts with %d black stones.\n\nWhite plays first.\nWhite receives %s points at the count.\n\n%s\n\nPress H to read the explanation." % ["You" if setup.player_color == GoBoard.BLACK else request.opponent_name, setup.handicap, MatchPresentation.number(setup.komi), MatchPresentation.stakes(request)]])
    _show()


func _show() -> void:
    _body.text = _reason_pages[_reason_page] if _reason else _pages[_page]
    _footer.text = "Space: next  Esc: back" if _reason else ("Space: next  Esc: skip\nRight: why this many?" if _page < _pages.size() - 1 else "Space: play  H: explain\nRight: why this many?")


func _input(event: InputEvent) -> void:
    # Own the entire event, including mouse input, so closing cannot place a stone.
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("move_right") and not _reason:
        _reason = true
        _reason_page = 0
    elif event.is_action_pressed("go_help"):
        _pages = MatchPresentation.handicap_pages(request, setup)
        _page = 0
        _reason = false
    elif event.is_action_pressed("cancel"):
        if _reason:
            _reason = false
        else:
            _close()
            return
    elif event.is_action_pressed("interact"):
        if _reason:
            _reason_page += 1
            if _reason_page >= _reason_pages.size():
                _reason = false
                _reason_page = 0
        else:
            _page += 1
            if _page >= _pages.size():
                _close()
                return
    _show()


func _close() -> void:
    closed.emit()
    queue_free()
