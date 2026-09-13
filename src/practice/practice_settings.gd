class_name PracticeSettings
extends RefCounted

const SIZES := [7, 9, 13, 19]
const AVATARS := ["wren", "pip", "kesh", "hana", "bertie", "nadia", "tomas", "marguerite", "joos", "ilse", "sunny", "orla", "abel", "dov", "moss", "noor", "ivo", "lea", "emil", "sora"]
var mode := "ordinary"
var board_size := 9
var rank := 0
var avatar := "wren"
var style := "balanced"
var colour := "black"
var handicap_mode := "none"
var stones := 2
var player_rank := 0
var player_name := "You"
var komi := 5.5
var custom_komi := false

func to_dict() -> Dictionary:
    return {"mode": mode, "board_size": board_size, "rank": rank, "avatar": avatar,
        "style": style, "colour": colour, "handicap_mode": handicap_mode,
        "stones": stones, "player_rank": player_rank, "player_name": player_name, "komi": komi, "custom_komi": custom_komi}

static func from_dict(data: Dictionary) -> PracticeSettings:
    var out := PracticeSettings.new()
    for key in out.to_dict():
        if not data.has(key): continue
        var expected := typeof(out.get(key))
        if typeof(data[key]) == expected or (expected in [TYPE_INT, TYPE_FLOAT] and typeof(data[key]) in [TYPE_INT, TYPE_FLOAT]):
            out.set(key, data[key])
    if out.mode not in ["ordinary", "teaching", "capture"]: out.mode = "ordinary"
    if out.board_size not in SIZES: out.board_size = 9
    if out.avatar not in AVATARS: out.avatar = "wren"
    if out.style not in ["steady", "balanced", "fighting"]: out.style = "balanced"
    if out.colour not in ["black", "white", "nigiri"]: out.colour = "black"
    if out.handicap_mode not in ["none", "auto", "manual"]: out.handicap_mode = "none"
    out.rank = clampi(out.rank, 0, 34)
    out.player_rank = clampi(out.player_rank, 0, 34)
    out.stones = clampi(out.stones, 2, GoRank.max_handicap(out.board_size))
    out.komi = clampf(out.komi, -50.0, 50.0) if is_finite(out.komi) else 5.5
    out.player_name = out.player_name.strip_edges().left(24)
    if out.player_name.is_empty(): out.player_name = "You"
    return out

func rank_label() -> String:
    return GoRank.to_string_rank(rank) + (" (approx.)" if rank < 10 else "")

func resolve_setup() -> GoMatchSetup:
    if mode == "capture":
        return GoMatchSetup.prepare(GoMatchSetup.Rule.PLAYER_BLACK, -1, -1, 7, 0.0)
    var rule := GoMatchSetup.Rule.PLAYER_BLACK
    if colour == "white": rule = GoMatchSetup.Rule.PLAYER_WHITE
    if colour == "nigiri": rule = GoMatchSetup.Rule.NIGIRI
    if handicap_mode == "auto": rule = GoMatchSetup.Rule.BY_RANK
    var setup := GoMatchSetup.prepare(rule, player_rank, rank, board_size, komi if custom_komi else 5.5)
    if handicap_mode == "manual":
        setup.handicap = clampi(stones, 2, GoRank.max_handicap(board_size))
        setup.player_color = GoBoard.WHITE if colour == "white" else GoBoard.BLACK
        setup.komi = 0.5
        setup.uses_nigiri = false
        setup.resolved = true
        setup.explanation = "Black starts with %d stones; White moves first." % setup.handicap
    if custom_komi: setup.komi = komi
    return setup

func summary() -> String:
    if mode == "capture": return "7×7 · First capture wins\nCapture practice uses its own opponent, without a full-Go rank."
    var setup := resolve_setup()
    var who := "Nigiri" if setup.uses_nigiri else "You play " + GoBoard.color_name(setup.player_color)
    return "%d×%d · %s · %s\n%s · %d handicap stones · komi %.1f" % [board_size, board_size,
        rank_label(), style.capitalize(), who, setup.handicap, setup.komi]
