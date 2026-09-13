# Launch, native rendering and default audio

The normal launcher refreshes Godot imports and script classes before opening the game.
One retry handles a theme that initially references a missing imported font. A remaining
error stops launch and prints diagnostics. Recovery was exercised by removing the cached
font and launching through `tools/play.sh`; normal user saves were not used by tests.

`NativeViewportSize` sizes 3D render targets to their displayed pixel rectangle, including
root stretch, nested portrait scales and letterboxing. World layout and board input retain
their existing logical coordinates. Higher window resolutions require more rendering work.

![Production world at 1920×1080](world-1080p.png)

The normal audio directory now contains the approved Thwack recordings, capture/bowl
contacts and new Kettle/rated-match music. Their old synthesis recipes and runtime
audition controls were removed. Other location, lesson, character and UI cues remain.
`tools/adopt_audio.py` publishes checksum-verified source renders under production names;
the audio build also publishes them, so rebuilding cannot restore the retired sounds.

![Production 13×13 table, with no audition overlay](table.png)

Verified with isolated user data on 2026-09-13:

- `tools/test.sh`: 406 resource loads and 19,569 main checks; production audio contact,
  pure review/teaching, capture and real KataGo integration gates all passed.
- Rendered board verification: 3,806 checks, including every intersection on 7/9/13/19
  boards at 768×432, 1536×864, 1920×1080 and letterboxed 1600×1200.
- `table_adoption`: 105 checks for native world resizing, legal placements, counting,
  one saved result per game and returning to the world. Replayed after audio adoption.
- `opening`: title, Hana/board introduction and rooftop arrival inspected at 1080p.
- Production audio driver launched through `tools/play.sh`, with no audio flag:
  19 checks; effects peaked between -8.8 and -12.5 dB, music around -21.8 dB;
  intro handover and loop restarts worked. Removed audition keys had no effect.
- Audio contact: 48 checks at 30/60/144 fps, including redraw and destruction cancellation.
- Three Python audio asset tests verify source integrity and exact production bytes.

Rendered verification used software OpenGL; native GPU performance was not benchmarked.
Driver measurements establish output and routing, not a new independent aesthetic review.
Full local logs and captures are under `/home/user/.cache/ninepoint-default-audio/` and
`/home/user/.cache/ninepoint-resolution/`.
