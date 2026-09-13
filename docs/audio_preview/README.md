# Weight at the board, warmth in the room

AUDIO-01 is a session-only audio preview using the latest campaign graphics. Normal production audio and saves remain unchanged.

```bash
tools/play_audio_preview.sh              # Kettle; talk to Wren for a rated rematch
tools/play_audio_preview.sh --baseline   # same graphics, original audio
```

- **F6** cycles Original → Snap → Thunk → Deep. Thunk is the default. Each new family has six variants without immediate repeats.
- **F7** switches original/new music for the current context.
- **F8** mutes/unmutes only music; table effects remain audible.

The three stone families share a recorded wood/contact foundation. Snap emphasizes the attack; Thunk adds a rounded wooden body; Deep extends the lower resonance. Captures and nigiri use separate, lighter glass/bowl contacts. Background tables keep their original quiet knocks.

**A Seat at the Table** (Kettle, 84 BPM, 114.29 s): original piano melody with electric-piano harmony, fingerpicked guitar, upright bass and brushes. **Across the Board** (rated matches, 112 BPM, 102.86 s plus 2.14 s introduction) develops the melody with a firmer rhythm and occasional strings, then thins the middle section. Lessons and named-opponent/occasion themes retain their existing routing.

Run `python3 tools/audio_preview/serve.py` and open `http://127.0.0.1:8793/`, or open [index.html](index.html) for listening comparisons and gameplay films. [Verification](verification.md) distinguishes measurements and visual inspection from the human listening decision still required.

## Rebuilding

The renderer requires the exact versions in `tools/audio_preview/toolchain.json`. On the configured workstation:

```bash
nix-shell -p fluidsynth ffmpeg 'python3.withPackages (p: [p.numpy p.scipy p.pillow])' --run 'python3 tools/build_audio_preview.py'
# Or opt in through the central coordinator:
# python3 tools/build_assets.py --groups audio_preview
```

`--output /absolute/path` builds independently for deterministic comparison. `--only effects` / `--only music` selectively regenerate exports. Default production builds exclude this group.

Edit `tools/audio_preview/score.py` for notes, arrangement, instrumentation, dynamics and timing; `effects.py` for contact layers and resonances; `dsp.py` for processing and loudness. Python renders MIDI with FluidSynth and processes WAV files with NumPy/SciPy and FFmpeg. Runtime uses 48 kHz mono effects and stereo music, with no synthesizer or network dependency.

`tools/audio_preview/sources.json` records immutable source URLs and SHA-256 hashes. The original Kenney archive and GeneralUser instrument bank/license are preserved in `sources/`; missing files can be fetched by the builder, but checksum mismatches stop the build. [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) is CC0. GeneralUser GS 2.0.3 uses its included license; retain its complete terms and sample-provenance note. Compositions and synthesized board resonances are original to this project.

## Acceptance and media

```bash
tools/run_audio_preview.sh
# Optional normal-speed movie; use unique OUT/LOG paths for each serial run:
# MOVIE=/home/user/.cache/audio-wren.avi tools/run_audio_preview.sh
# Run the real-driver probe with NINEPOINT_AUDIO_PREVIEW=1 on a display:
# godot --path . --script res://tools/audio_preview/driver.gd
```

Contact verification: `NINEPOINT_AUDIO_PREVIEW=1 NINEPOINT_PRESENTATION=campaign_next godot --headless --path . --script res://tools/audio_preview/verify.gd`, after an editor import pass. Use an absolute disposable `XDG_DATA_HOME` under `/home/user` for all tests. Run game/engine acceptance serially.

`tools/audio_preview/package.py` exports the listening comparisons and compressed music previews; `--movie INPUT.avi NAME` encodes a Godot recording without changing its speed. The standalone stone comparison uses six hits of Original, Snap, Thunk and Deep in that order, each followed by one second of silence. All four segments are matched to -24 LUFS in the repeat test; the in-game Original option retains its production level.

The comparison replay is explicitly prepared, with legal moves and capture reactions; `live.log` and the Wren film cover the separate real-engine game, count, review and return. Neither route establishes whether a listener prefers the new sounds.
