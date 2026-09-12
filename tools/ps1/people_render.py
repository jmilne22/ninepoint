import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from people import build
build(Path(sys.argv[sys.argv.index('--')+1]),all_cast=True)
