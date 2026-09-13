# Walking, running and mirrored tram cab correction (ART-13R)

This follows the owner's report that the rollout slides instead of walking/running and
has a broken tram end. Work is isolated on `codex/locomotion-tram-fix`, after fetching and
proving `HEAD == origin/main == f90a39e`, then replaying the approved local rollout chain.

## Cause

The live follower estimated velocity from differences between rendered frames. At 144 fps,
many frames occurred between the 60 Hz physics steps: zero displacement incorrectly meant
"stand". The next physics step meant "walk" again. Repeated animation crossfades prevented
the legs from completing a stride. [The reproduction](before-motion.log) records 73/72
clip changes in about 0.6 seconds and only 0.046 model units of foot travel. The earlier
30 fps movie did not expose this refresh-rate-dependent defect.

Movement is now sampled after actors move, once per physics tick, and retained across render
frames. Cadence follows actual displacement and each model's scale. Running has its own
bent-arm, higher-clearance stride; changing gait retains the foot-cycle phase. Collisions,
input, player movement speed and saves are unchanged.

One cab mirrored vertices without reversing face winding. Its shell and windscreen normals
pointed inward, so the campaign shader culled them. The source generator now reverses those
faces. The asset contract checks every cab shell/window normal at both ends.

[Godot's processing documentation](https://docs.godotengine.org/en/4.6/tutorials/scripting/idle_and_physics_processing.html)
describes the separate render and fixed physics callbacks behind the first defect.

## Play the corrected full game

```bash
/home/user/Code/ninepoint-motion-fix/tools/play_motion_fix.sh
```

The launcher uses its own persistent saves under `~/.local/share/ninepoint-motion-preview`
so an older rollout preview can remain open safely.

## Reproduce the checks

```bash
# Rebuild authored locomotion and both cab meshes:
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_expressive_world.py --people --tram'
# Import before the rendered routes, with isolated data:
XDG_DATA_HOME=/home/user/.cache/ninepoint-motion-test godot --headless --path . --editor --quit
DISPLAY=:0 XDG_DATA_HOME=/home/user/.cache/ninepoint-motion-test godot --path . --disable-vsync res://tools/expressive_world/motion_review.tscn
DISPLAY=:0 XDG_DATA_HOME=/home/user/.cache/ninepoint-motion-test OUT=/home/user/.cache/ninepoint-tram-shots godot --path . res://tools/expressive_world/tram_review.tscn
DISPLAY_NUM=0 OUT=/home/user/.cache/ninepoint-tram-stop tools/run_rendered.sh tools/autopilot/rendered_tram.json
XDG_DATA_HOME=/home/user/.cache/ninepoint-motion-gate tools/test.sh
```

`motion_review` presses the real player controls at 30, 60 and 144 fps caps, inspects the
live foot bone, then tests input release, a real collision wall and an input lock.
`--film` selects a longer normal-speed 30 fps capture route; it is visual evidence, not
the 144 fps regression check. `tram_review` presents both sides of both cabs, using the
actual campaign shader with back-face culling enabled.


## Inspected evidence

The [full technical gate](technical-gate.log) passes **19,407 / 0**, loads **380**
resources, and passes the Capture Go and real KataGo smoke/service/review integrations.
The movement and boarding routes ran serially with isolated user data.

- [Normal-speed movement clip](movement.mp4): 8.5 seconds, actual Godot Movie Maker,
  1536×864 / 30 fps, H.264 + stereo AAC; opened and watched at 1× in the app browser.
  [Capture log](movie-capture.log), [stream metadata](media-info.json),
  [audio levels](audio-levels.txt): −26.1 dB mean / −7.4 dB peak.
- [Both cabs from four angles](both-cabs.jpg), with [the broken west cab](before-west-cab.png)
  retained for comparison. Opened all four corrected views and the complete vehicle.
- [Actual tram held at the platform](boarding/01_tram_held_at_platform.png),
  [boarding regression log](boarding.log).
- [Render-rate regression log](after-motion.log): all six walk/run cases pass, zero
  idle frames or clip changes during movement at each rate. At 144 fps, foot travel
  is 0.520 walking / 0.712 running versus 0.046 for both before. Release, collision
  and input-lock checks pass. The numeric checks use the real player and live skeleton.
- 26 rebuilt identities × 160 deformed-pose assertions = 4,160 passed. The asset gate
  now checks the run clips and both cab normals: 134 checks (previously 119).

The normal-speed movie and static cab inspection complement the high-refresh runtime
check; neither alone establishes the other's behaviour. Some harnesses retain the
existing shutdown ObjectDB/resource diagnostics. No engine profile, logical map,
movement speed, collision rule or save schema was changed.
