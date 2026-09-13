# Expressive matches — inspected evidence

The approved style now covers all 20 opponents plus the player, ordinary and Capture
Go matches, 7/9/13/19 boards, colour selection, teaching, counting and results.
Launch `tools/play.sh` for the campaign or `tools/play_table_scene.sh` for disposable
Wren practice. `tools/play_table_scene.sh --opponent=tomas --board=13` opens Tomás.

- Full technical gate: 19,406 / 0, 349 resource loads, 13 Python art tests, 21 cast contracts.
- Rendered trial: 1,162 / 0, including every intersection and 19×19 zoom regions.
- Production size/input/count/record/return route: 98 / 0.
- Actual Wren and Tomás GTP replies: 9 / 0 each, no fallback.
- `rendered_match`, `table_nigiri`, both teaching comparisons, `mouse_capture`,
  and full `capture_practice` routes completed serially with disposable data.
- Inspected all seven cast/gesture contact sheets, nigiri choice, all board sizes,
  teaching/handicap panels, Capture Go win and saved before/after replay.

[Actual gameplay movie](showcase.mp4): 39.23 seconds, 768×432, 30 fps H.264, stereo AAC.
Captured with Godot MovieWriter at normal animation speed, watched in the browser at
1× through the ending. Delivery audio reduced 3 dB for headroom (peak −2.9 dB).

Six captures: [opening](showcase/01_table_for_two.png),
[placement](showcase/02_placing_a_stone.png), [thinking](showcase/03_thinking.png),
[capture surprise](showcase/04_wren_surprised.png),
[capture relief](showcase/05_wren_relief.png), [counting](showcase/06_counting_together.png).
Other evidence is in `gallery`, `campaign`, `nigiri`, `sizes`, `teaching-wren`,
`teaching-kesh`, `capture-complete`, `live` and `live-tomas`.

Limits: world, lesson and review presentation remain their existing style pending
the next scoped experiment. Teaching comparisons completed within the existing
2-second budget on the real GPU (Wren 1,833 ms; Kesh 1,980 ms); software rendering can
miss that deadline and uses the existing graceful skip. Some automated exits report
an AudioStreamWAV/playback resource warning for club music; the verbose trace
identifies audio shutdown, not a match controller leak.
