## Which track plays under which game.
##
## MatchMusic is pure and static precisely so this can exist: every branch is
## reachable with a MatchRequest built by hand, no scene, no audio server and no
## wav on disk. That matters because the failure this guards against is silent
## in the worst way -- the wrong music is not an error, it is a mood, and the
## only way to notice it in play is to already know what you were expecting.
class_name MatchMusicTests
extends RefCounted


static func run(t: TestKit) -> void:
    _test_tiers(t)
    _test_people(t)
    _test_occasions(t)
    _test_every_named_track_exists(t)


static func _request(theme: String, unrated: bool, context: String = "") -> MatchRequest:
    var req := MatchRequest.new()
    req.context_id = context
    req.unrated = unrated
    var profile := OpponentProfile.new()
    profile.theme = theme
    req.profile = profile
    return req


static func _test_tiers(t: TestKit) -> void:
    t.section("match music: a game that counts sounds different from one that does not")
    t.eq(MatchMusic.theme_for(_request("", true)), MatchMusic.DEFAULT,
        "a free game keeps the quiet bed")
    t.eq(MatchMusic.theme_for(_request("", false)), MatchMusic.BATTLE,
        "a rated game gets the battle theme")
    # The match scene falls back to a debug request when run standalone, and a
    # null one must not take the audio layer down with it.
    t.eq(MatchMusic.theme_for(null), MatchMusic.DEFAULT,
        "no request at all is the bed, not a crash")
    var no_profile := MatchRequest.new()
    no_profile.unrated = false
    t.eq(MatchMusic.theme_for(no_profile), MatchMusic.BATTLE,
        "a request with no profile still tiers")


static func _test_people(t: TestKit) -> void:
    t.section("match music: the person outranks the tier")
    t.eq(MatchMusic.theme_for(_request("theme_rival", false)), "theme_rival",
        "a named theme beats the battle default")
    # Joos is the case this rule exists for. His games are unrated so that
    # LeagueTable never sees them, and by the tier alone the most intimidating
    # opponent in the game would be played out over the lesson bed.
    t.eq(MatchMusic.theme_for(_request("theme_ghost", true)), "theme_ghost",
        "Joos is unrated and still gets his own theme")

    # And the profiles really do carry them, which is the half a table keyed by
    # character could not do: the teaching game is not the fight.
    var fight := load("res://data/opponents/hana_9x9.tres") as OpponentProfile
    var lesson := load("res://data/opponents/hana_teaching.tres") as OpponentProfile
    t.eq(fight.theme, "theme_teacher", "Hana playing you has her own theme")
    t.eq(lesson.theme, "", "Hana teaching you does not")


static func _test_occasions(t: TestKit) -> void:
    t.section("match music: the occasion outranks the person")
    var exam := _request("theme_wall", false, Exam.context_for(0))
    t.eq(MatchMusic.theme_for(exam), MatchMusic.EXAM,
        "an exam round sounds like the exam whoever the draw produced")
    var cup := _request("theme_rival", false, CupDraw.context_for(2))
    t.eq(MatchMusic.theme_for(cup), MatchMusic.CUP,
        "a Cup round sounds like the Cup whoever the draw produced")
    # A league game is neither, and must not be caught by a loose prefix match.
    t.eq(MatchMusic.theme_for(_request("", false, "league_orla")), MatchMusic.BATTLE,
        "a league game is a rated game, not an occasion")


static func _test_every_named_track_exists(t: TestKit) -> void:
    t.section("match music: every track anybody can choose is on disk")
    # play_music() returns quietly on a name it does not have and leaves the
    # previous track playing, so a typo here is inaudible as an error and merely
    # sounds wrong. Nothing else in the project would catch it.
    var named := [MatchMusic.DEFAULT, MatchMusic.BATTLE, MatchMusic.EXAM, MatchMusic.CUP]
    var dir := DirAccess.open("res://data/opponents")
    if dir != null:
        for f in dir.get_files():
            var file_name := f.trim_suffix(".remap")
            if not file_name.ends_with(".tres"):
                continue
            var profile := load("res://data/opponents/%s" % file_name) as OpponentProfile
            if profile != null and profile.theme != "" and not named.has(profile.theme):
                named.append(profile.theme)
    t.ok(named.size() >= 8, "the cast between them name at least eight tracks")
    for track in named:
        t.ok(FileAccess.file_exists("res://audio/%s.wav" % track),
            "audio/%s.wav exists" % track)
