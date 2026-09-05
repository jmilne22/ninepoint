class_name MatchPresentation
extends RefCounted


static func kind(request: MatchRequest, capture_goal: int = 0) -> String:
    if capture_goal > 0:
        return "Capture Go"
    if not request.unrated:
        return "Rated game"
    return "Practice" if request.practice else "Casual game"


static func stakes(request: MatchRequest) -> String:
    return "This game does not change your rank." if request.unrated else "This result counts toward your rank."


static func introduction(request: MatchRequest, setup: GoMatchSetup, goal: int) -> String:
    if goal > 0:
        return "Capture %s to win." % ("one stone" if goal == 1 else "%d stones" % goal)
    if setup.is_handicap():
        return "White plays first. H explains handicap stones."
    return request.intro_line if request.intro_line != "" else "You play %s." % GoBoard.color_name(setup.player_color)


static func details(request: MatchRequest, setup: GoMatchSetup, game: GoGame) -> String:
    var rows := "%dx%d  %s\nYou play %s" % [game.size(), game.size(), kind(request, game.capture_goal), GoBoard.color_name(setup.player_color)]
    if game.capture_goal > 0:
        return rows + "\nCapture %d stone%s to win\nMove %d" % [game.capture_goal, "" if game.capture_goal == 1 else "s", game.move_number()]
    rows += "\nHandicap: %d stones" % setup.handicap if setup.is_handicap() else "\nNo starting stones"
    return rows + "\nWhite gets %s points" % number(setup.komi)


static func handicap_pages(request: MatchRequest, setup: GoMatchSetup) -> PackedStringArray:
    var black := "You play Black" if setup.player_color == GoBoard.BLACK else "%s plays Black" % request.opponent_name
    var first := "Handicap stones give the weaker player a head start.\n\n%s with %d stones already on the board.\n\nWhite makes the first move after these stones are placed. %s" % [black, setup.handicap, "You play White." if setup.player_color == GoBoard.WHITE else request.opponent_name + " plays White."]
    var second := "These are ordinary stones. They stay where placed, join groups and can be captured.\n\nKomi means points added to White's score: %s in this game." % number(setup.komi)
    if is_equal_approx(setup.komi, 0.5):
        second += " The half-point prevents a tie."
    second += "\n\n" + stakes(request)
    return PackedStringArray([first, second])


static func handicap_reason(request: MatchRequest, setup: GoMatchSetup) -> String:
    if request.opponent_rank == "?":
        return "%s does not have a published rank. This game uses an agreed head start of %d stones.\n\nOn this board, the starting positions are fixed. The highlighted stones show them." % [request.opponent_name, setup.handicap]
    if request.profile.colour_rule != "by_rank":
        return "This teaching game starts with %d stones. The person setting the game chose this head start." % setup.handicap
    return "Your rank: %s\n%s: %s\n\nThe gap is %d ranks. On %dx%d, divide that by %d and round to the nearest stone.\n\nThe limit is %d starting stones on this board. This game uses %d." % [GoRank.to_string_rank(request.player_strength), request.opponent_name, request.opponent_rank, absi(request.player_strength - GoRank.from_string(request.opponent_rank)), setup.board_size, setup.board_size, GoRank.ranks_per_stone(setup.board_size), GoRank.max_handicap(setup.board_size), setup.handicap]


static func number(value: float) -> String:
    return "%.1f" % value if not is_equal_approx(value, roundf(value)) else str(int(value))
