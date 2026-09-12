## Questions concern named evidence, never a suggested answer or an invented tactic.
class_name TeachingPolicy
extends RefCounted

const LOSS_THRESHOLD := 4.0
const COOLDOWN := 5
var committed_turns := 0
var _last_question := -COOLDOWN
var _asked_positions := {}


func commit_turn() -> void:
    committed_turns += 1


func question(facts: Dictionary, loss: float, position_key: String) -> Dictionary:
    if not is_finite(loss) or loss < LOSS_THRESHOLD or _asked_positions.has(position_key) \
            or committed_turns - _last_question < COOLDOWN:
        return {}
    var out := {}
    for kind in ["group_died", "group_saved", "region_lost"]:
        for item: Dictionary in facts.get(kind, []):
            var anchor := str(item.get("anchor", ""))
            if kind == "group_died":
                out = {"text": "Before that move, how many liberties did your group at %s have?" % anchor,
                    "targets": item["stones"]}
            elif kind == "group_saved":
                out = {"text": "Before that move, how many liberties did the opposing group at %s have?" % anchor,
                    "targets": item["stones"]}
            elif int(item.get("points", 0)) >= 4:
                out = {"text": "Which stones protect the %s around %s?" % [item["area"], anchor],
                    "targets": item["members"]}
            if not out.is_empty():
                _last_question = committed_turns
                _asked_positions[position_key] = true
                return out
    return {}


## A weak opponent need not follow the review PV. Only explain a matching real reply.
static func reply_note(facts: Dictionary, game: GoGame, player: int, name: String) -> String:
    var line: Array = facts.get("refutation", [])
    var move := game.last_move()
    if line.is_empty() or move.is_empty() or int(move["point"]) < 0 \
            or int(move["color"]) != GoBoard.opponent(player) \
            or line[0]["role"] != "opponent" or line[0]["point"] != move["point"]:
        return ""
    var prefix := "%s played %s. " % [name, move["label"]]
    for group: Dictionary in facts.get("group_died", []):
        var captured: Array = []
        for point in move["captured"]:
            captured.append(game.board.label(point))
        if group["stones"].all(func(label: String) -> bool: return captured.has(label)):
            return prefix + "That captured your group at %s." % group["anchor"]
        var point := game.board.from_label(group["anchor"])
        if point >= 0 and game.board.cells[point] == player:
            var liberties: PackedInt32Array = game.board.chain_at(point)["liberties"]
            if liberties.size() == 1:
                return prefix + "Your group at %s now has one liberty, %s." % [group["anchor"], game.board.label(liberties[0])]
    return ""
