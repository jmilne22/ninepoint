# Design audit: method and evidence

12 September 2026. [Recommendation and implementation plan](PLAN.md).

## Revision and scope

The checkout began two merges behind main, with unrelated untracked local tooling and
old screenshot imports. Fetched, fast-forwarded main and verified both hashes:
`89e1a35dbf68ada472ce68d4d2af858a64df6b9a`. Then created
`codex/design-baseline-audit`. Existing untracked files were left alone.

This is a design investigation and documentation change. No production source,
dialogue, generated content, opponent setting or artwork was changed. Screenshots are
captures of the existing game, not proposed concept art. No merge or release is claimed.

Godot 4.7.2 ran through `/home/user/.local/bin/godot` after a clean editor import.
The bare `godot` name was not on this shell's PATH. All sessions used separate absolute
`XDG_DATA_HOME`, `OUT` and `LOG` directories beneath
`/home/user/.cache/ninepoint-design-audit`; the runner serialized play under its lock.
The user's actual save slots were not used.

## Played observations

### Live opening, Pip and teaching

The existing `live_file` harness accepted small batches of real input actions. I selected
Pip's moves from the visible board, without autoplay or an analysis recommendation. I used
the harness's known tile/NPC navigation helpers, so this is not unaided wayfinding evidence.

- Opened the title, Hana's two-line introduction, attic text, street, Pip's greeting,
  capture offer and board, result, return interaction, Kettle and Wren's experience choices.
- Won Pip's Capture Go on ply 7. Black D4, C5, C3, B4; White C4, D5, B5.
  [Saved SGF](pip-win.sgf), [before capture](screenshots/pip-before-capture.png),
  [win](screenshots/pip-capture-win.png), [return choices](screenshots/pip-return.png).
- Local `gtp_logs/20260912-153150-ED7F0EE1.log` confirms the 18k fighting config,
  `boardsize 7`, `komi 0.5` and three White replies ([retained log](pip-engine.log)).
  The runtime log contains no fallback.
- Wren's four rules and four finishing beats were subsequently driven by the existing
  `lesson_run` helper. They are scripted lesson coverage, not independently solved puzzles.
  Opened the initial instructions, small rule position, dense finishing position and count
  feedback. [Finishing position](screenshots/wren-finishing.png).

Three navigation/choice attempts in this exploratory session failed because I sent a
walking command during unfinished narration, selected New Game when intending Continue,
and later requested a lesson choice the helper had already passed. The harness exited;
I resumed from disposable saves or used the maintained fresh route below. These are
investigator/harness errors, not evidence that players cannot navigate or that the game
crashed. The seven-ply Pip game was completed and saved before the later lesson-choice error.
This is not presented as an uninterrupted cold-start playthrough.

### Fresh maintained journey

`tools/autopilot/kesh_skip.json`: **exit 0, zero script errors, 80 captures**.
[Run log](journey.log). New Game → Pip → Wren rules/finishing/openings → first-game
Help → result/reaction → card without a Kesh game → actual tram → Hana's welcome/class
→ registration → novice board/room → save/reload.

Pip's automated game lost by capture at 22 plies. Wren's game was deliberately resigned
after one ply by the route; it is not a completed difficulty assessment. No Kesh match
was manufactured. Opened both opening brief pages, Wren Help, the card, institute arrival,
Hana's direction, [zero-game league](screenshots/novice-league.png), and
[novice-room arrival](screenshots/novice-room.png).

The comparison between a live Pip win in 7 plies and an automated loss in 22 is evidence
of two possible outcomes, not a sample sufficient to estimate difficulty or randomness.

### Full Wren game and review

The [Wren route](wren-route.json) uses the maintained `rendered_match` route from its
declared `lost_to_kesh` fixture, with its eight-player-move limit increased to 160. The
automated heuristic chose Black's moves; the ordinary Wren engine chose White's. It
reached counting after 44 player moves, before that limit, and returned a Black win by
17.5. This is a **rated club rematch**, not Wren's introductory practice and not a game
I personally won. No fallback was logged. **Exit 0, zero script errors, 19 captures**.
[Log](wren.log), [result](screenshots/wren-result.png).

Opened the count, result, review summary and costly-position card, then verified room
return and walking. Analysis completed. The summary compared 44 player placements with
seven preferred moves. One recommendation valued C8 about 40.3 points above played F6,
while its immediate explanation compared group liberties. The qualification is honest;
that display alone does not teach why the large difference exists.
[Review card](screenshots/wren-review.png). This reinforces the existing learning-transfer
question without establishing that the engine's estimate is wrong.

### Twelve-map presentation and all-loss competition route

`tools/autopilot/art_tour.json`: **exit 0, zero script errors, 18 captures**.
[Log](tour.log). Opened representative views of all twelve maps: rooftop, Market Lane,
Kettle, Laundry, Arcade, Sea Walk, institute hall/study/classroom/dorm/novices and Assembly
Hall. The route uses declared visit/setup helpers; this is visual inspection, not evidence
of unaided navigation. The existing [laundry](screenshots/laundry.png) and
[street](screenshots/market-lane.png) already establish ordinary surroundings. The proposal
concerns how the story uses these places, not whether the art depicts a functioning city.

`tools/autopilot/novice_losses.json`: **exit 0, zero script errors, 88 captures**.
[Log](competition.log). Started from its declared `novice_ready` fixture. The script
deliberately resigned every game: five novice fixtures, followed by four Cup rounds. Opened
the [0–5 league](screenshots/novice-losses.png), the final Cup's 9×9/three-stone setup,
Marguerite's completion response, the [0–4 Cup table](screenshots/cup-complete.png), and
the [next attempt starting at zero](screenshots/repeat-attempt.png). The route asserted
both completion flags and the 30k rank floor. The Cup table correctly says sixth of six.

This verifies access to the ending and another attempt after losses. It establishes
neither that those nine opponents are beatable by beginners nor that losing nine games
feels satisfying. Together with the fresh journey, it covers the main progression in
separate declared sessions; it is not one continuous personally played campaign.

### Capture Go ending reproduction

[pass-route.json](pass-route.json) uses the fresh-start portion of `kesh_skip`, then ordinary
P-key inputs at intervals, screen captures, count confirmation and result dismissal.
It changes no game state directly. **Exit 0, zero script errors, 21 captures**.
[Run log](pass.log). Pip placed stones while Black passed. Eventually the game counted;
acceptance showed White winning by 46.5 with **zero prisoners on both sides**.
[Observed result](screenshots/pip-no-captures-result.png).

This is an intentional terminal-path probe, not a plausible whole beginner game and not
the user's unrecovered save. Its purpose is to show that an offered control can end a
first-capture game on a different victory condition.

The separate [pure probe](capture-probe.gd) instantiates the existing `GoGame`, sets
`capture_goal = 1`, passes twice and uses the existing scoring path. It reaches `SCORING`
with zero captures, then returns White +0.5 on an empty board.
[Output](capture-probe.log). This uses no engine and isolates the rules/state transition
from the opponent's choice of when to pass.

To reproduce from the project root, use fresh audit output paths; these commands keep
the test saves separate from the user's slots:

```bash
XDG_DATA_HOME=/home/user/.cache/ninepoint-capture-repro/data /home/user/.local/bin/godot --headless --path . --editor --quit
XDG_DATA_HOME=/home/user/.cache/ninepoint-capture-repro/data /home/user/.local/bin/godot --headless --path . --script res://docs/design-audit/capture-probe.gd
XDG_DATA_HOME=/home/user/.cache/ninepoint-capture-repro/data OUT=/home/user/.cache/ninepoint-capture-repro/shots LOG=/home/user/.cache/ninepoint-capture-repro/play.log tools/run_game.sh docs/design-audit/pass-route.json
```

## Documentation investigation

Inventoried all **29 repository Markdown documents present at the reviewed base**.
Read the current product/technical contracts and relevant play reports; examined milestone
history by system and investigated the source where its claims met these concerns. This
does not mean every historical art recipe or every old assertion was rerun.

| Documents | What they contributed |
|---|---|
| `AGENTS.md`, `CLAUDE.md` | Current constraints, original inspirations, isolation and evidence rules; CLAUDE delegates to AGENTS. |
| `GAME_DESIGN.md`, `README.md` | Promised newcomer route, motivation, person-first pillar, current player controls, old chapter/venue claims that conflict with newer sections. |
| `WORKBOARD.md`, `ROADMAP.md` | CAP-01 is distinct from ordinary-Go stopping; preserve existing CONTENT-05, ENG-09 and PROG-01 decisions and human gates. |
| `ARCHITECTURE.md` | Pure rules, opponent interface, MatchBridge, result/review and save boundaries; current lesson/presence mechanisms. |
| `ART_DIRECTION.md` | Current rendered Sela presentation and historical fallback; a fiction repair need not commission a new city. |
| `MILESTONES.md` | M11 capture contract; M13 zero-knowledge opening; M14 explicitly identifies coincidence as weak premise; M37 system cuts; M38–41 engine/strength evidence; M43/M45 teaching; M46–49 presentation limits. Other milestone sections were indexed and examined for related predecessor decisions. |
| `HANDOFF_ENG-06.md` | Historical hypotheses, correctly superseded by measurements; latency is not strength. |
| `data/dialogue/VOICES.md` | Concrete circumstances and motivations, rules beside positions, actual-result reactions and ordinary exchanges. |
| `docs/early-game/BEFORE.md`, `PLAYTEST.md` | Prior manually chosen Pip win/loss, full Wren/Noor/Ivo games, unchanged strengths and unresolved transfer/pacing problems. Historical evidence, not games played during this audit. |
| `docs/novice/PLAYTEST.md`, `KESH-WELCOME.md` | Close-ish owner wins, 72 bot-game experiment, independent rank gate and optional-card/practice repair. |
| `docs/overhaul/PLAYTEST.md`, `GALLERY.md` | Prior setting/writing work and deliberate resignation/fixture limits. |
| `docs/polish/PLAYTEST.md`, `docs/mouse/PLAYTEST.md` | Pip previously reached counting; mouse Capture Go coverage ended by resignation. Neither established first-capture teaching quality. |
| `docs/sela/DESIGN.md`, `PLAYTEST.md` | Current community premise, coastal rationale, unchanged curriculum and explicit automation limitations. |
| `docs/art/PLAYTEST.md`, `docs/sprite-preview/PLAYTEST.md` | Historical presentation changes; no beginner-strength acceptance claimed. |
| `docs/ps1/README.md`, `world/README.md`, `world/verification.md`, `world/tram.md`, `polish/verification.md`, `polish/references.md` | Current rendered build, preserved game logic, visual evidence and reference scope; separate old room prototype. |

Printed and read the connected Pip/Wren/Kesh/Hana/Noor/Ivo/Abel/Dov/Moss/Tomás dialogue
graphs with `tools/check_dialogue.py`, alongside opening/intro and early lesson data.
The script output is retained in the local audit cache. These were content inspection,
not claims to have visited every branch in play.

## Source findings to verify during implementation

| Source | Finding |
|---|---|
| `data/opponents/pip_capture.tres`, `packaging/katago/config/human_18k_fighting.cfg` | 7×7 first capture layered on an ordinary 18k Human-SL Japanese-rules opponent. |
| `src/go_ai/gtp_opponent.gd` | Synchronizes stones/moves/komi, not a capture win condition. |
| `src/go/go_game.gd:173` | Two passes enter `SCORING` without checking the variant. |
| `src/go_ui/go_match.gd:327` | Every `SCORING` game opens the normal counting phase. |
| `src/go_ui/match_teaching.gd:12` | Position guidance limited to `wren_first`. |
| `data/dialogue/pip.json` | Completed Capture Go switches the next offer to 9×9, with no capture retry. |
| `src/go_ai/heuristic_opponent.gd` | Self-atari candidate exclusion and territory-based stopping are independent of capture objective. |
| `src/go_ai/match_analysis.gd:27` | Eligibility excludes capture *results*, not every Capture Go encounter; audit resignation/pass-ended paths. |
| `tests/test_go_setup.gd` | Capture terminal condition covered; double-pass variant contract absent. |
| `src/ui/opening.gd:11` | Explicit city-wide Go framing. |

## Limits

This is an AI design walkthrough with selected manual decisions, scripted route coverage,
source investigation and screenshot inspection. Existing Go knowledge cannot be erased.
It measures neither beginner learning nor enjoyment, and no proposed human acceptance
target is claimed met. No subjective audio assessment was performed. No statistically
meaningful opponent-strength sweep was needed to establish the observed contract failures.
The full test suite was not rerun for a documentation-only proposal; editor import, the
focused pure probe and the played routes provide the relevant new evidence.

The plan deliberately preserves existing shipped work while recording two new decisions.
No milestone or “SHIPPED” claim is added; no user's result or rank is altered.

The retained GTP log has trailing whitespace trimmed for repository hygiene; command,
reply and timing content is unchanged.
