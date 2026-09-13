"""Serial cast, locomotion, contact and performance review; stop on the first failure."""
import subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
base=[sys.executable,'tools/campaign_next/capture.py']
jobs=[
 ['tools/campaign_next/gallery.tscn','--tag','cast','--film'],
 ['tools/campaign_next/gallery.tscn','--tag','baseline-cast','--profile','baseline'],
 ['src/experiments/table_scene/gallery.tscn','--tag','match-cast'],
 ['tools/campaign_next/portraits.tscn','--tag','portraits'],
 ['tools/expressive_world/motion_review.tscn','--tag','movement-rates'],
 ['tools/expressive_world/motion_review.tscn','--tag','movement','--film'],
 ['tools/kettle_next/contact.tscn','--tag','counter-contact'],
 *[['tools/campaign_next/benchmark.tscn','--tag','performance-'+profile,'--profile',profile] for profile in ['baseline','kettle','campaign']],
]
start = int(sys.argv[1]) if len(sys.argv)>1 else 0
for job in jobs[start:]:
 print('START',job,flush=True)
 subprocess.run(base+job,cwd=ROOT,check=True)
 print('DONE',job[2],flush=True)
