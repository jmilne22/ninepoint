# Local club baseline: implementation and played evidence

12 September 2026 · Base `89e1a35` · `codex/cap-01-first-capture`.
The owner approved the [played audit and plan](../design-audit/PLAN.md), then asked for
implementation to continue while away. CAP-01 and DESIGN-01 are implemented and technically
verified. **Their independent human acceptance remains open.**

## Delivered behavior

Ninepoint now introduces a newcomer joining a small Go club and preparing for a first local
amateur Cup. Hana invites the player to her club; Pip connects them with the Kettle group.
Wren volunteers with beginners and Kesh helps with novice registration. The teaching rooms
are rented space in a community centre. Internal `academy_*` IDs and existing geography
remain intact. The game still selects a hobby community: all twenty named characters can
play Go. It does not attempt a representative city population or simulate ordinary jobs.

Kesh names Noor and her Cup ambition before travel. Hana offers a direct route to meet her
before class/registration, without silently marking the class skipped. Noor offers company,
accepts hesitation, can talk about her postcard, and acknowledges league/Cup completion on
return. Those acknowledgements use completion facts, not invented performance or affection.
The actual post-game reaction still follows the latest win/loss. A missed league conversation
cannot surface as a stale first-Cup invitation after completion; seen facts survive loading.

Tomás's welcome, Abel's basket and Noor's postcard can end as ordinary exchanges. Stationer,
snack-window and bar notices describe ordinary use. Wren's initial menu also allows leaving.
No shops, economy, quest rewards, schedules or relationship system were added.

The [capture report](../capture/PLAYTEST.md) covers Pip's demonstration, optional dedicated
practice policy, help/retry, neutral ending and saved exact capture replay. Ordinary cast
strength, Wren's supported full game, Kesh's card-before-practice, the rank ladder and
loss-tolerant novice/Cup progression retain their existing contracts.

## Runs and visual inspection

All runs used declared saves and distinct `XDG_DATA_HOME` directories under
`/home/user/.cache/ninepoint-cap01`. One GUI runner operated at a time. Routes use UI actions,
state-aware setup/lesson helpers and an explicitly automated player where indicated.
**These are route/behavior checks, not independent human playtests.**

| Route | Coverage / result |
|---|---|
| `capture_practice` | Fresh example, H help, two-pass neutral end, retry/resignation, retry/capture, save/reload, before/after replay, Wren; 30 frames |
| `capture_skip` | Leave demonstration, take directions, save/reload, Wren lesson without a capture game; 9 frames |
| `club_journey` | Fresh start through Pip/Wren lessons; deliberately resign Wren; novice card without Kesh match; tram, Noor before class/registration, postcard, Hana class, zero league, reload; 92 frames |
| `beginner_full_games` | Same fresh route, but play Wren fully, then first real Noor/Ivo league fixtures, reactions and review refusal; 114 frames |
| `club_everyday` | Explicit early-rules fixture and direct venue visits for Tomás, Wren's club/refusal menu, Abel, ordinary notices and centre directory; zero new records; 12 frames |
| `club_payoff` | Novice-ready fixture, actual five novice resignations, Noor checkpoint, actual four Cup resignations, honest sixth place, repeat league at zero, Noor Cup return and reload; 94 frames |

All completed with exit 0 and no script/parse errors. Representative actual images were
opened: demonstration/feedback/help/neutral/resign/capture/replay, opening and tram labels,
Wren's measured menu, Noor's pre-enrolment invitation and postcard, all three full-game
results and Ivo's count, ordinary exchanges/notices/directory, league/Cup loss tables,
Noor's checkpoint/payoff and post-load menu. Some processes report ObjectDB/resource cleanup
warnings at exit; these are recorded in the logs, not silently classified as script success.
No audio change or subjective audio assessment was part of this work.

Selected evidence:

- [Opening](screenshots/opening.png), [Wren's club](screenshots/wren-club.png),
  [Noor before registration](screenshots/noor-invitation.png), [postcard](screenshots/noor-postcard.png).
- [Tomás](screenshots/tomas-neighbour.png), [Abel](screenshots/abel-basket.png),
  [stationer](screenshots/stationer.png), [snack window](screenshots/snack-window.png),
  [directory](screenshots/directory.png).
- [Five league losses](screenshots/league-losses.png), [Noor checkpoint](screenshots/noor-league-return.png),
  [four Cup losses](screenshots/cup-losses.png), [Noor return](screenshots/noor-cup-return.png),
  [reloaded menu](screenshots/noor-reloaded.png).

## First full games: what they do and do not establish

The normal engine profiles were installed; no fallback was logged in this route. The player
was the harness's **12k-labelled heuristic**, seed 7, reading depth 1, mistake rate 0.05.
That label itself is not independently calibrated. It chose the moves; these were not
my manually chosen victories. No fixture injected the three results. All were Black,
9×9, no handicap, 5.5 komi. The harness accepted proposed dead marks automatically, so
the displayed scores are not independent adjudication of the final positions.

| Encounter | Placements by player / total plies | Recorded result | Pass trace (1-based SGF ply) |
|---|---|---|---|
| Supported `wren_first`, unrated | 44 / 89 | Black +10.5 | White 68, 70, 72, 74, 76, 80, 84, 86, 88; Black 89 |
| First `league_noor`, rated | 40 / 89 | Black +78.5 | Black 75, 77, 81, 83, 89; White 88 |
| First `league_ivo`, rated | 44 / 89 | Black +74.5 | White 88; Black 89 |

[Wren SGF](wren_first.sgf), [Noor SGF](league_noor.sgf), [Ivo SGF](league_ivo.sgf),
[actual save](full-games-save.json), [route log](full-games.log).
[Wren result](screenshots/wren-result.png), [Noor result](screenshots/noor-result.png),
[Ivo result](screenshots/ivo-result.png), [Ivo proposed count](screenshots/ivo-count.png).

Wren passed repeatedly while the stronger automated player continued; against Noor the
player passed several times while White continued, then replied again. The saved positions
make ENG-09 reproducible. The traces alone do not establish whether any particular pass
was sensible, whether a novice understood the continuation, or whether all dead marks were
correct. None reached the 160-placement cutoff. None demonstrates a suitable beginner win
rate. Ivo's final pair of passes does not close the broader stopping question.

CONTENT-05 explicitly retains Wren's strength pending a human comparison. PROG-01 requires
independent novice validation, and ENG-09/ENG-05 separate stopping from dead-group judgment.
No ordinary engine tuning, concealed weakening or rank relabelling was justified by these
bot games. The next useful evidence is the [prepared human protocol](BEGINNER-PLAYTEST.md),
not another automated strength run presented as learner experience.

## Technical gate and corrections caught

Final `tools/test.sh`: **18,017 passed, 0 failed** (predecessor M49: 17,239), **316 files load**,
13 Python art tests, actual capture-scene gate and all three real KataGo integration gates.
`tools/check_lessons.py`: zero problems. Changed dialogue was read as a connected script
with `tools/check_dialogue.py`; its machine writing rules also pass in the data suite.
[Full gate log](technical-gate.log), [lesson check](lessons.log).

The old service test cast a first-capture opponent to GtpOpponent, then printed “passed”
after the awaited function failed. The final test retains ordinary 7×7 GTP synchronization
coverage and delegates capture bypass to the real scene probe. The shell gate now rejects
script/parse/compile errors even when Godot exits zero. The initial failed run is excluded
from the final pass claim. A run interrupted by editing its still-running shell script is
also excluded; the final stable script was rerun completely.

Other corrections from inspection: neutral result wording no longer duplicates its heading;
Wren does not claim a skipped capture was learned; new dialogue choices are handled by
maintained routes; Noor's payoff suppresses stale invitations after loading; all brief pages
and the expanded Wren menu fit the actual board/window.

## Generated assets and document reconciliation

Map names/signs/warp prompts were changed in generators and regenerated. Their whole-JSON
hashes invalidate rendered manifests even though the renderer does not consume those text
fields. Before using the existing `build_world_art.stamp_manifest`, an exact comparison
removed **only** `name`, `sign.text` and `warp.prompt` and asserted that every remaining
field matched the base. All seven changed map inputs passed. Render geometry, PNGs, depth
and footprint inputs were unchanged. [Provenance check](map-provenance.log).
The legacy community-centre arrival caption was regenerated and its actual image opened.

README, GAME_DESIGN, AGENTS, ARCHITECTURE, ART_DIRECTION, VOICES, ROADMAP and WORKBOARD now
state the current baseline. The stale chapter table, laundry-record blanket claim, Joos
handicap blanket claim and ENG-08's pre-PROG-02 Kesh summary were reconciled. Old play reports
and the original audit remain historical evidence; they were not rewritten as new results.

The implementation is reviewable now. CAP-01 and DESIGN-01 remain blocked only on their
explicit human gates; CONTENT-05 / ENG-09 / PROG-01 are not falsely marked shipped. No human
participants, quotations, recruitment or calibrated rank claims were fabricated.
