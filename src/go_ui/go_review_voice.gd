## What one character says about a finding.
##
## The findings are facts about the board; this is the half that makes them a
## person talking. Each file overlays data/reviews/default.json, so a character
## only writes the lines they would say differently -- Joos overrides nearly
## everything and says almost nothing, Wren overrides almost nothing and cannot
## review you at all.
class_name GoReviewVoice
extends RefCounted

const DIR := "res://data/reviews/"
const FALLBACK := "default"

var id: String = ""
var intro: PackedStringArray = PackedStringArray()
var outro: PackedStringArray = PackedStringArray()
## What somebody weaker than you says when asked to explain your own game.
var unqualified: PackedStringArray = PackedStringArray()
var lines: Dictionary = {}
## The rule behind a finding, one portable sentence per kind. Not per character:
## the voice is whose mouth it comes out of, and this is the thing that is true
## whoever says it, so it lives only in default.json.
var takeaways: Dictionary = {}
## What this player keeps doing, from GoReviewHistory. Fills {again}: a teacher
## who has watched you lose the same group five weeks running says so, and one
## who says the identical sentence five times has not been watching.
var habits: Dictionary = {}


static func load_voice(npc_id: String) -> GoReviewVoice:
	var v := GoReviewVoice.new()
	v.id = npc_id
	v._merge(FALLBACK)
	if npc_id != "" and npc_id != FALLBACK:
		v._merge(npc_id)
	return v


func _merge(which: String) -> void:
	var path := DIR + which + ".json"
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("GoReviewVoice: %s is not valid JSON" % path)
		return
	if parsed.has("intro"):
		intro = PackedStringArray(parsed["intro"])
	if parsed.has("outro"):
		outro = PackedStringArray(parsed["outro"])
	if parsed.has("unqualified"):
		unqualified = PackedStringArray(parsed["unqualified"])
	for kind in parsed.get("lines", {}):
		lines[kind] = PackedStringArray(parsed["lines"][kind])
	for kind in parsed.get("takeaways", {}):
		takeaways[kind] = str(parsed["takeaways"][kind])


## The line for one finding, or "" when this voice has nothing for that kind.
##
## Deterministic rather than random: a teacher who says something different
## about the same board the second time you look at it is not a teacher. But it
## is keyed on the game as well as the move, because the same board twice is
## rare and the same *kind* twice is not -- a player who ignores atari in six
## games running should not hear one sentence six times.
func speak(finding: Dictionary, board: GoBoard, seed: int = 0) -> String:
	var kind := str(finding.get("kind", ""))
	if not lines.has(kind):
		return ""
	var options: PackedStringArray = lines[kind]
	if options.is_empty():
		return ""
	var pick: int = absi(int(finding.get("move_index", 0)) + seed * 7) % options.size()
	return _fill(options[pick], finding, board)


## The rule the finding is an instance of, or "" -- praise carries no lesson.
func takeaway(finding: Dictionary) -> String:
	return str(takeaways.get(str(finding.get("kind", "")), ""))


static func _count(n: int, noun: String) -> String:
	return "%d %s" % [n, noun if n == 1 else noun + "s"]


func _fill(text: String, finding: Dictionary, board: GoBoard) -> String:
	var detail: Dictionary = finding.get("detail", {})
	# Move numbers are what a person says out loud, and people count from one.
	text = text.replace("{move}", str(int(finding.get("move_index", 0)) + 1))
	# Counted things are substituted as a whole phrase rather than a bare number,
	# because "1 points" is the kind of thing that makes a person stop believing
	# the sentence around it -- and every line here is trying to be believed.
	for key in ["stones", "points"]:
		if detail.has(key):
			text = text.replace("{%s}" % key,
				_count(int(detail[key]), "stone" if key == "stones" else "point"))
	for key in ["tries", "until"]:
		if detail.has(key):
			text = text.replace("{%s}" % key, str(int(detail[key])))
	text = text.replace("{count}", str(int(finding.get("instances", 1))))
	text = text.replace("{again}",
		GoReviewHistory.again_for(habits, str(finding.get("kind", ""))))
	text = text.replace("{cost}", str(int(roundf(float(finding.get("cost", 0.0))))))
	# Points are named the way the board names them, so the sentence and the
	# coordinates down the side of the board agree with each other.
	for key in ["liberty", "save", "played"]:
		if detail.has(key):
			text = text.replace("{%s}" % key, board.label(int(detail[key])))
	# {again} is usually empty, and an empty placeholder must not leave a double
	# space or a space before a full stop behind it. The prose is the product.
	return text.replace("  ", " ").strip_edges()
