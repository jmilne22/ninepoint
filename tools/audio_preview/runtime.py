"""Stage 768x432 MovieWriter output, preserving source and disposable saves."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[2]
target = Path(sys.argv[1]).resolve()
target.mkdir(parents=True, exist_ok=True)
for name in ['src', 'art', 'audio', 'audio_preview', 'data', 'packaging', 'tools', 'tests', '.godot', 'docs']:
    (target/name).symlink_to(ROOT/name, target_is_directory=True)
project = (ROOT/'project.godot').read_text().replace('viewport_width=384', 'viewport_width=768').replace('viewport_height=216', 'viewport_height=432')
(target/'project.godot').write_text(project)
