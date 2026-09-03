## Which track plays under a game of Go.
##
## theme_match was written to be ignored -- fifty-eight beats a minute, eight
## notes in half a minute -- and the comment in tools/gen_audio.py explaining why
## is right: anything busier competes with reading the position, which is the one
## thing the player is there to do. It is right for a lesson, a puzzle, and a
## game in the park. It was wrong for the rival who keeps score, the man under
## the arches, and the exam that ends Act 2, all of which sounded like a lesson.
##
## So the soundtrack tiers, the way Pokemon's does: a free game keeps the bed, a
## game that costs an hour and goes on your record gets the upbeat theme, and
## eight people and two occasions get their own. The line between free and
## costly is `MatchRequest.unrated`, which the day economy already draws -- this
## reuses a distinction the game makes rather than inventing a parallel one.
##
## Pure and static on purpose: tests/test_match_music.gd checks every branch
## with no scene, no audio server and no wav on disk.
class_name MatchMusic
extends RefCounted

## The quiet bed. A lesson, a puzzle, a pickup game in the park.
const DEFAULT := "theme_match"
## Anything that costs you an hour and goes on your record.
const BATTLE := "theme_battle"
## The two occasions, which outrank the person sitting across the board.
const EXAM := "theme_exam"
const CUP := "theme_cup"


## Highest match wins. The order is the whole design, so it is worth stating:
##
## 1. The occasion beats the person. The exam is Act 2's ending and the Cup is
##    the only thing that happens in a hall; whoever the draw produces, those
##    two sound like themselves.
## 2. The person beats the tier. This is what makes Joos work -- his games are
##    `unrated` so LeagueTable never sees them, and by the tier alone he would
##    get the quiet bed, which is the exact opposite of the truth about him.
## 3. Otherwise the tier: rated is a fight, free is not.
static func theme_for(request: MatchRequest) -> String:
    if request == null:
        return DEFAULT
    if request.context_id.begins_with(Exam.CONTEXT_PREFIX):
        return EXAM
    if request.context_id.begins_with(CupDraw.CONTEXT_PREFIX):
        return CUP
    if request.profile != null and request.profile.theme != "":
        return request.profile.theme
    return DEFAULT if request.unrated else BATTLE
