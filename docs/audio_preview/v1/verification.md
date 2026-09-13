Archived first-pass evidence from commit e226c99. Links to shared production or launcher media are unchanged references.

# AUDIO-01 verification

Base: `578c3c0c175f48f221fef10fd5b1625bebef99ea`, fetched and verified against live `origin/main` before creating the isolated `codex/audio-preview` worktree. This is an implemented preview awaiting owner listening review, not a full soundtrack replacement or production adoption.

## Asset and playback evidence

- 24 exported 48 kHz WAV files: 18 stone variations, three table effects, two music loops and one intro. Effects are mono; music is stereo. Source checksums and renderer versions are pinned.
- Two independent builds produced byte-identical WAV files: [determinism.txt](determinism.txt). All assets retain more than 1 dB peak headroom.
- All 18 stone variants fall within 0.34 LU of -24 LUFS when repeated once per second. Both music loops measure -21 LUFS. These are file measurements; the game applies its existing Music/SFX bus levels. [Asset checks](asset-checks.txt), [manifest](manifest.json).
- The real audio-driver probe verifies all four stone options, table effects, intro/loop selection, loop restart, original-stream restoration and actual F6/F7/F8 key input: **21 passed / 0 failed**. Music mute leaves effects active. [driver.log](driver.log).
- The recorded preview's first stone sound correlates with the source waveform at **2.209 s**, versus the landing event at **2.200 s**: **9.37 ms** difference, inside one 30 FPS frame. This is one recorded sample, not a hardware-latency guarantee. [Recorded sync](recorded-sync.json), [contact frames](contact-frames.jpg).

## Technical gate

`tools/test.sh` passes: **405 resources load, 19,805 main checks pass / 0 fail**, with the pure-review, teaching, capture and KataGo service/review gates also passing. [technical-gate.log](technical-gate.log). The existing KataGo review shutdown still reports seven ObjectDB instances/three resources in use; it does not fail its assertions or the gate.

The unchanged production catalog passes its real-driver check: **18 tracks audible and all four intro stings hand over**. [production-audio.log](production-audio.log). All test and fixture user data was isolated from player saves.

## Interaction checks

The real board-surface probe exercises 30/60/144 FPS: sound fires with the stone grounded, exactly once; capture follows the landing by a short gap. It also covers silent restoration/redraw, an intent announced after the visual update, rebuilding during descent, offscreen moves, scene exit before contact and scene exit before the delayed capture. **48 passed / 0 failed**. [contact.log](contact.log).

Variation selection runs 120 draws per family, checks no immediate repeats and exercises all six samples. Default Thunk, baseline capture/bowl restoration and distinct capture sizes are covered in the main suite. The Python asset suite validates source hashes, exported hashes, formats, durations, headroom and loudness tolerance.

## Played and inspected

The complete Wren route uses her real GTP opponent and exercises Kettle → nigiri → rated match → count → result → post-match reaction → complete engine review → room return. The final run records 31 player moves, 31 legal engine replies with no fallback, all 65 review positions, exactly one saved result and room return. Its probe rejects fallback, partial review and duplicate recording. The delivered film is 2,048 frames at 30 FPS (68.27 seconds). [Live log](live.log), [normal-speed film](wren.mp4).

The matched A/B films use the same **21 legal moves**, including single and two-stone captures, and run **1,234 frames / 41.13 seconds each**. They are prepared fixtures rather than evidence of engine strength. [Original](../baseline.mp4), [preview](preview.mp4), [sequential comparison](../comparison.mp4).

Both actual disposable launchers passed startup in The Kettle, with the expected original/new music profile and no script errors. [Preview launcher](launcher/preview.log), [baseline launcher](launcher/baseline.log).

Opened representative Kettle, match, result/review/return images and the four contact frames around the first placement. Inspected the listening-page layout and verified browser playback and video metadata. Recording inspection caught and corrected an unsuitable table-only viewport setup for world footage. Preview controls were moved away from the opponent name and world toast area.

## Limits

The existing room-name badge overlaps part of the long review-ready toast in the return frame; the audio panel stays clear of both. This preview does not change that existing world layout.

No subjective listening judgment is claimed. The assistant inspected score/source structure, waveforms, measured output and visual evidence; the preference between Snap/Thunk/Deep, long-session fatigue and whether the music feels right for Sela require human listening. Use the playable preview and the review page for that decision.

The cue scope remains The Kettle and generic rated matches. Named opponent themes, tournament cues, lessons, street music, footsteps, dialogue blips and result jingles are existing production audio. New recordings were not acquired from the anime. GeneralUser's complete supplied license, including its sample-provenance note, is retained beside the source bank.
