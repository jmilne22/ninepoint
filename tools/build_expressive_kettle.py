#!/usr/bin/env python3
"""Coordinate the isolated Kettle POC's generated art, using Blender and Pillow."""
import subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(root/'tools/expressive_kettle/paint.py')],check=True)
subprocess.run(['blender','--background','--python',str(root/'tools/expressive_kettle/build.py')],check=True)
