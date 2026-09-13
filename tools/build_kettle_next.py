#!/usr/bin/env python3
"""Build only the opt-in Kettle prototype; Blender and Pillow are required."""
import argparse,subprocess,sys,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--people',nargs='*');p.add_argument('--room',action='store_true');a=p.parse_args()
all_groups=a.people is None and not a.room
if a.people is not None or all_groups:
    subprocess.run([sys.executable,str(ROOT/"tools/kettle_next/paint.py")],check=True)
    subprocess.run(['blender','-b','-t','4','--python-exit-code','1','--python',str(ROOT/'tools/kettle_next/build.py'),'--','people',*(a.people or [])],check=True)
if a.room or all_groups:
    subprocess.run(['blender','-b','-t','4','--python-exit-code','1','--python',str(ROOT/'tools/kettle_next/build.py'),'--','room'],check=True)

    subprocess.run(['blender','-b','-t','4','--python-exit-code','1','--python',str(ROOT/'tools/kettle_next/build.py'),'--','table'],check=True)
