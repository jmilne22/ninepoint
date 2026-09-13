# Presentation decisions

- The approved Kettle is the design benchmark; this task broadens its coverage, not the game rules or setting.
- `campaign_next` is a process-only preview. The original default and Kettle-only profile remain independently launchable. It is intentionally not published or merged by the preview task.
- Board supersampling converts at the render/input boundary. Picking geometry, logical layout and GoBoardView behavior remain authoritative. The existing projected-world gate now compares equivalent logical coordinates at either resolution.
- Cast animation retains actual-displacement cadence and gait phase. All named and background identities have explicit proportions and timing entries; their original painted faces and colours remain authoritative. Clothing details use the shared rig, not a separate portrait model.
- Maps use unchanged data and prop footprints. Window fills are derived from the source window rectangles. Source-generated manifests identify cup steam positions and map hashes.
- Campaign environment materials use standard diffuse lighting after rendered diagnosis exposed triangular bands in the custom light pass. The shadow atlas uses 32-bit depth, a single orthogonal map and bounded camera depth (12–55 metres) within the preview process. This removes the large-range shadow acne while preserving the camera composition.
- The capture harness uses actual Godot rendering, disposable data and the existing exclusive game lock. Movies use 30 frames per second and retain their captured timebase. Autopilot navigation is acceptance tooling, not a change to player controls.

No lip sync, simulated cloth, terrain IK, new progression, dialogue rewrites, engine-strength changes or save migration are introduced.

Compatible skinned pieces are joined by material after animation/deformation validation. Three posed vertex clouds must remain equal within 0.02 mm before export. Painted face meshes stay separate. Original seated venues remain seated after activity variations; the presentation does not alter NPC locations or interaction state. Embedded lesson/review boards use separately generated quiet wood and softer stone sprites.
