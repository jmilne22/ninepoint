# Production audio — THWACK and melodic drama

AUDIO-02 adopts AUDIO-01 revision 02 at the owner's request. Normal play now uses the
Thwack recordings, capture/bowl contacts and new Kettle/rated-match music. The superseded
production audio, old synthesis recipes, audition flag and F6/F7/F8 controls are removed.

```bash
tools/play.sh                          # normal campaign and existing saves
tools/play_audio_preview.sh            # disposable Kettle visit, same production audio
```

The current palette uses six Thwack variants without immediate repeats. The earlier
Original/Snap/Thunk/Deep comparisons and first-pass compositions below are historical
listening evidence, not selectable game modes.

The four new stone families share a recorded wood/contact foundation. Snap emphasizes the attack; Thunk adds a rounded wooden body; Deep extends the lower resonance. Thwack adds a dense, dry slap and a brief wooden body; its six variants match the earlier alternatives in audition loudness. Captures and nigiri use separate, lighter glass/bowl contacts. Background tables use the new recorded contact at their existing quiet positional levels.

**Beyond the Balcony** (Kettle, 88 BPM, 109.09 s): original piano melody with strings, oboe/cello answers, guitar and brushes. **One Clear Move** (rated matches, 116 BPM, 99.31 s plus 2.07 s entrance) develops the same original melody through active strings, electric bass, drums and restrained guitar/brass. The quieter middle begins at 0:33; the brighter ensemble statement enters at 0:50. Lessons and named-opponent/occasion themes retain their existing routing.

Run `python3 tools/audio_preview/serve.py` and open `http://127.0.0.1:8793/`, or open [index.html](index.html) for listening comparisons and gameplay films. [Verification](verification.md) distinguishes measurements and visual inspection from the earlier human listening questions.

## Rebuilding

The renderer requires the exact versions in `tools/audio_preview/toolchain.json`. On the configured workstation:

```bash
nix-shell -p fluidsynth ffmpeg 'python3.withPackages (p: [p.numpy p.scipy p.pillow])' --run 'python3 tools/build_audio_preview.py && python3 tools/adopt_audio.py'
# Or rebuild and publish through the central coordinator:
# python3 tools/build_assets.py --groups audio_preview
```

`--output /absolute/path` builds independently for deterministic comparison. `--only effects` / `--only music` selectively regenerate exports. The `audio` build publishes the checked-in approved renders alongside retained synthesis. The `audio_preview` group rebuilds the source renders and publishes them into production `audio/`.

Historical first-pass compositions remain in `score_v1.py`; its music and films are archived in `docs/audio_preview/v1/` for comparison.

Edit `tools/audio_preview/score.py` for notes, arrangement, instrumentation, dynamics and timing; `effects.py` for contact layers and resonances; `dsp.py` for processing and loudness. Python renders MIDI with FluidSynth and processes WAV files with NumPy/SciPy and FFmpeg. Runtime uses 48 kHz mono effects and stereo music, with no synthesizer or network dependency.

`tools/audio_preview/sources.json` records immutable source URLs and SHA-256 hashes. The original Kenney archive and GeneralUser instrument bank/license are preserved in `sources/`; missing files can be fetched by the builder, but checksum mismatches stop the build. [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) is CC0. GeneralUser GS 2.0.3 uses its included license; retain its complete terms and sample-provenance note. Compositions and synthesized board resonances are original to this project.

## Acceptance and media

```bash
tools/run_audio_preview.sh
# Optional normal-speed movie; use unique OUT/LOG paths for each serial run:
# MOVIE=/home/user/.cache/audio-wren.avi tools/run_audio_preview.sh
# Run the production real-driver probe on a display:
# godot --path . --script res://tools/audio_preview/driver.gd
```

Contact verification: `godot --headless --path . --script res://tools/audio_preview/verify.gd`, after an editor import pass. Use an absolute disposable `XDG_DATA_HOME` under `/home/user` for all tests. Run game/engine acceptance serially.

`tools/audio_preview/package.py` exports the listening comparisons and compressed music previews; `--movie INPUT.avi NAME` encodes a Godot recording without changing its speed. The archived standalone stone comparison used six hits of Original, Snap, Thunk, Deep and Thwack in that order, each followed by one second of silence. All five segments are matched to -24 LUFS in the repeat test; the archived Original segment retained its then-production level.

The comparison replay is explicitly prepared, with legal moves and capture reactions; `live.log` and the Wren film cover the separate real-engine game, count, review and return. Neither route establishes whether a listener prefers the new sounds.

The first comparison on the page is the earlier Thunk followed by the new Thwack. [Reference notes](references.md) record the owner’s three named tracks and the limits of source inspection.

## AUDIO-02 default adoption verification

`tools/adopt_audio.py` validates every selected source against `audio_preview/manifest.json`
before replacing production WAVs. The production names keep existing music routing and
intro handover. `tests/test_audio_assets.py` verifies exact rendered bytes and proves the
retired synthesis recipes cannot overwrite them. Non-replaced UI, location and character
cues remain available.

The standard `tools/play.sh` launcher ran the real-driver probe with no audio environment
flag: all six Thwack samples, single/group captures and the bowl were audible (-8.8 to
-12.5 dB bus peaks), and both music loops were audible (about -21.8 dB). Intro handover
and loop restarts passed, and the removed audition keys did not change music. Contact
checks passed at 30/60/144 fps, including redraw and scene-destruction cancellation.
Logs and rendered acceptance captures: `/home/user/.cache/ninepoint-default-audio/`.
