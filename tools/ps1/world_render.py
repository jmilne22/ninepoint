import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
args=sys.argv[sys.argv.index('--')+1:]
from world.scene import build
build(Path(args[0]),args[1])
