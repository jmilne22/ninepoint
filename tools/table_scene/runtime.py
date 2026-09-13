"""Stage the trial viewport settings before Godot (and MovieWriter) initializes."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[2]
target = Path(sys.argv[1]).resolve()
target.mkdir(parents=True, exist_ok=True)
for name in ['src', 'art', 'audio', 'data', 'packaging', 'tools', 'tests', '.godot']:
    (target/name).symlink_to(ROOT/name, target_is_directory=True)
project = (ROOT/'project.godot').read_text()
for old,new in [('viewport_width=384','viewport_width=768'),
                ('viewport_height=216','viewport_height=432'),
                ('window_width_override=1152','window_width_override=1536'),
                ('window_height_override=648','window_height_override=864')]:
    project = project.replace(old,new)
(target/'project.godot').write_text(project)
