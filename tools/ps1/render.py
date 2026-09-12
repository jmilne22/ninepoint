"""Blender entry point; called by build_ps1.py, not imported by the normal build."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
args = sys.argv[sys.argv.index('--')+1:]
output = Path(args[0]).resolve()
if args[1] == 'room':
    from room import build
    build(output)
else:
    from people import build
    build(output, preview=args[1] == 'preview')
