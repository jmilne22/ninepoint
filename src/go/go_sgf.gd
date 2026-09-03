## Minimal SGF writer, used for debugging, reviews and future kifu screens.
class_name GoSgf
extends RefCounted

static func to_sgf(game: GoGame, meta: Dictionary = {}) -> String:
    var s := "(;GM[1]FF[4]CA[UTF-8]"
    s += "SZ[%d]" % game.size()
    s += "KM[%s]" % str(game.komi)
    if game.handicap >= 2:
        s += "HA[%d]" % game.handicap
    for key in ["PB", "PW", "EV", "DT", "RE"]:
        if meta.has(key):
            s += "%s[%s]" % [key, str(meta[key]).replace("]", "\\]")]
    if game.handicap >= 2:
        var ab := ""
        for i in GoGame.handicap_points(game.size(), game.handicap):
            ab += "[%s]" % _coord(game.board, i)
        s += "AB" + ab
    for m in game.moves:
        var tag := "B" if m["color"] == GoBoard.BLACK else "W"
        if m["point"] == GoGame.PASS:
            s += ";%s[]" % tag
        elif m["point"] == GoGame.RESIGN:
            continue
        else:
            s += ";%s[%s]" % [tag, _coord(game.board, m["point"])]
    s += ")"
    return s


static func _coord(board: GoBoard, i: int) -> String:
    var p := board.point(i)
    var letters := "abcdefghijklmnopqrstuvwxyz"
    return "%s%s" % [letters[p.x], letters[p.y]]
