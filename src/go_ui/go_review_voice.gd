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


## The line for one finding, or "" when this voice has nothing for that kind.
##
## The choice is deterministic in the move number rather than random: a teacher
## who says something different about the same board the second time you look
## at it is not a teacher.
func speak(finding: Dictionary, board: GoBoard) -> String:
	var kind := str(finding.get("kind", ""))
	if not lines.has(kind):
		return ""
	var options: PackedStringArray = lines[kind]
	if options.is_empty():
		return ""
	var text: String = options[int(finding.get("move_index", 0)) % options.size()]
	return _fill(text, finding, board)


func _fill(text: String, finding: Dictionary, board: GoBoard) -> String:
	var detail: Dictionary = finding.get("detail", {})
	# Move numbers are what a person says out loud, and people count from one.
	text = text.replace("{move}", str(int(finding.get("move_index", 0)) + 1))
	for key in ["stones", "tries"]:
		if detail.has(key):
			text = text.replace("{%s}" % key, str(int(detail[key])))
	# Points are named the way the board names them, so the sentence and the
	# coordinates down the side of the board agree with each other.
	for key in ["liberty", "save", "played"]:
		if detail.has(key):
			text = text.replace("{%s}" % key, board.label(int(detail[key])))
	return text
