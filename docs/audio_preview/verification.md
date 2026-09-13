# AUDIO-01 revision 02 verification

The owner requested a sharper **THWACK** and more dramatic music, naming **Majiwaru Michi**, **Shukuteki** and **Mezame**. This revision extends the isolated `codex/audio-preview` checkout. A fresh fetch again confirmed its base matches `origin/main`: `578c3c0c175f48f221fef10fd5b1625bebef99ea`. Production adoption remains pending listening review.

## Assets and sound

- **30 exported 48 kHz WAVs**: 24 stone variations, three table effects, two music loops and one entrance. Mono effects, stereo music. Sources and exact renderer versions remain pinned.
- **30/30 byte-identical** files from independent builds. [determinism.txt](determinism.txt).
- All stone alternatives are within **0.34 LU of -24 LUFS** in the repeated-hit audition. The new Thwack variations are within **0.05 LU**. Every export has at least **1.89 dB** peak headroom. The two music loops measure -21 LUFS. [Measurements](asset-checks.txt), [manifest](../../audio_preview/manifest.json).
- Thwack uses short recorded wood/glass contact layers, a brief band-limited slap and dry damped wooden modes. Soft saturation controls the attack’s crest factor before loudness matching. Six variations never immediately repeat. The earlier Snap/Thunk/Deep choices remain available.
- The new original cues are **Beyond the Balcony**, 109.09 seconds at 88 BPM, and **One Clear Move**, 99.31 seconds at 116 BPM plus a 2.07-second entrance. The match’s lower-density middle starts at 0:33; its brighter ensemble statement enters at 0:50. First-pass compositions remain in `score_v1.py` and the [earlier listening files](v1/).

## Technical and playback checks

- Full `tools/test.sh`: **405 resources load; 19,926 main checks pass / 0 fail**, plus pure review, teaching, capture, KataGo service and review gates. [technical-gate.log](technical-gate.log). Headless teaching/capture/review harnesses report resource-in-use warnings at shutdown; their assertions and exit statuses pass. The preview contact and real-driver probes finish without those warnings.
- Actual board-surface probe at **30/60/144 FPS: 48 passed / 0 failed**. Exactly one grounded placement, ordered capture, quiet reconstruction, late move intent, redraw during descent, offscreen moves and scene-exit cancellation. [contact.log](contact.log).
- Real-driver probe: **22 passed / 0 failed**, covering all five stone options, table effects, music/intro handover and looping, restoration of original streams and actual F6/F7/F8 input. [driver.log](driver.log).
- The production stream catalog and QOA finished/replay workaround are unchanged. Its first-pass driver evidence remains [18 audible tracks / four intro handovers](production-audio.log). Every test/fixture uses isolated user data.

The first recorded Thwack correlates at **2.209 s**, versus the visual landing event at **2.200 s**: **9.37 ms**, inside one 30 FPS frame. This is one recorded placement, not a hardware-latency guarantee. [Sync record](recorded-sync.json), [opened contact frames](contact-frames.jpg).

## Review media

The listening page leads with equal-loudness **Thunk → Thwack**, then all five families and both full cues. The first-pass music and gameplay are retained for comparison. The matched prepared replay uses the same 21 legal moves as the production-audio reference, with single and group captures: 1,234 frames / 41.13 seconds per version. Representative board and group-capture frames were opened and inspected. The complete real-engine Wren route reached counting after 35 player moves, with 35 legal engine replies and no fallback; it reviewed all 73 positions, recorded exactly one result and returned to The Kettle. The normal-speed film is 2,147 frames / 71.57 seconds. [Live log](live.log), [film](wren.mp4). Nigiri, counting and room-return frames were opened and inspected.

Both actual disposable launchers again passed startup with the correct original/new music profile. The preview launcher shows Thwack as default. [Preview](launcher/preview.log), [baseline](launcher/baseline.log). The refreshed listening-page layout and native comparison playback were inspected.

## Listening limits

[Reference notes](references.md) distinguish verified track identification from musical interpretation. No direct listening analysis of the anime recordings is claimed, and no anime recording or transcribed melody enters the build. The score’s note sequences and orchestration are original.

Human review remains necessary for repeated-hit satisfaction, perceived contact, long-session fatigue and whether the music captures the desired drama. Waveform measurements, successful playback and visual inspection establish technical evidence rather than aesthetic agreement. The original room badge can overlap the long review-ready toast; the preview audio panel is clear of it.
