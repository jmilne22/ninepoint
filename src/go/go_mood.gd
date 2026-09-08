## What the person across the board looks like, given what just happened on it.
##
## Pure rules, like the rest of `src/go/`: in go tags from `GoTableTalk` and a
## standing from `GoTableTalk.standing()`, out comes the *name* of a mood. It
## returns a name and never a texture, so nothing here knows that portraits,
## atlases or a match scene exist.
##
## The same line `GoTableTalk` draws applies: these are reactions to OUTCOMES.
## A face falls because four stones came off, not because the move that lost
## them was a bad one -- judgement belongs to the review, after the game.
##
## It is also what finally consumes three things the rules layer had been
## computing into silence: `standing()`, and the two `edge_early` tags, which no
## character has ever had a line for.
class_name GoMood
extends RefCounted

const NEUTRAL := "neutral"

## Most specific first, matching the order GoTableTalk emits.
const BY_TAG := {
    "i_captured_big": "pleased",
    "i_captured": "pleased",
    "i_atari": "pleased",
    "you_captured_big": "worried",
    "you_captured": "annoyed",
    "you_atari": "worried",
    "ko": "thinking",
    "i_pass": "thinking",
    "you_pass": "thinking",
    "i_edge_early": "thinking",
    "you_edge_early": "thinking",
}

const BY_STANDING := {
    "winning": "pleased",
    "losing": "worried",
    "level": NEUTRAL,
}


## `tags` from GoTableTalk.events(), `standing` from GoTableTalk.standing().
## When nothing in particular happened, the face still says how the game is
## going, which is the difference between somebody playing you and a portrait.
##
## The caller decides when a standing is worth asking for. On a nearly empty
## board an area count says whoever played first owns everything -- true and
## useless -- and passing that in pins the face to one expression for the whole
## opening. Pass "" until the opening is over.
static func for_tags(tags: PackedStringArray, standing: String = "") -> String:
    for tag in tags:
        if BY_TAG.has(tag):
            return str(BY_TAG[tag])
    return str(BY_STANDING.get(standing, NEUTRAL))

