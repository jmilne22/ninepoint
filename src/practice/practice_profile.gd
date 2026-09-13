class_name PracticeProfile
extends RefCounted

static func make(settings: PracticeSettings) -> MatchRequest:
    var p := OpponentProfile.new()
    p.id = &"practice_ai"
    p.display_name = "Practice AI"
    p.rank_label = GoRank.to_string_rank(settings.rank)
    p.engine = "capture" if settings.mode == "capture" else "gtp"
    var setup := settings.resolve_setup()
    p.board_size = setup.board_size
    p.komi = setup.komi
    p.handicap = setup.handicap
    p.colour_rule = "nigiri" if setup.uses_nigiri else ("player_black" if setup.player_color == GoBoard.BLACK else "player_white")
    p.capture_goal = 1 if settings.mode == "capture" else 0
    p.gtp_style = settings.style
    p.gtp_command = "res://packaging/katago/katago-gtp.sh"
    p.gtp_model_path = KataGoAnalysis.MODEL
    p.gtp_config_path = "res://packaging/katago/config/practice/%s_%s.cfg" % [p.rank_label, settings.style]
    p.gtp_args = PackedStringArray(["gtp", "-config", "{config}", "-model", "{model}",
        "-human-model", "res://packaging/katago/models/b18c384nbt-humanv0.bin.gz"])
    p.gtp_time_per_move = 8.0 if p.board_size == 19 else (4.0 if p.board_size == 13 else 2.0)
    p.mistake_rate = 0.5
    var request := MatchRequest.new()
    request.profile = p
    request.context_id = "standalone_practice"
    request.opponent_name = "Practice AI"
    request.opponent_rank = settings.rank_label() if p.capture_goal == 0 else "Capture Go"
    request.portrait_path = "res://art/rendered/people/%s_portraits.png" % settings.avatar
    request.avatar_id = settings.avatar
    request.unrated = true
    request.practice = true
    request.teaching_enabled = settings.mode == "teaching"
    request.help_enabled = settings.mode != "ordinary"
    request.allow_undo = settings.mode == "teaching"
    request.player_strength = settings.player_rank
    return request
