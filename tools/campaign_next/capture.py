"""Serial real-renderer scene captures with disposable user data and optional 1x film."""
import argparse,fcntl,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('scene');p.add_argument('--profile',choices=['baseline','kettle','campaign'],default='campaign');p.add_argument('--tag',required=True);p.add_argument('--film',action='store_true');p.add_argument('--timeout',type=int,default=420);a=p.parse_args()
cache=Path.home()/'.cache/ninepoint-campaign-next';cache.mkdir(parents=True,exist_ok=True)
out=ROOT/'docs/campaign_next'/a.tag;out.mkdir(parents=True,exist_ok=True)
godot=str(Path.home()/'.local/bin/godot')
with open('/tmp/ninepoint-run.lock','w') as lock,tempfile.TemporaryDirectory(dir=cache) as data:
 fcntl.flock(lock,fcntl.LOCK_EX)
 env={**os.environ,'XDG_DATA_HOME':data,'DISPLAY':':0','OUT':str(out)}
 if a.profile=='baseline':env.pop('NINEPOINT_PRESENTATION',None)
 else:env['NINEPOINT_PRESENTATION']='kettle_next' if a.profile=='kettle' else 'campaign_next'
 with (cache/'scene-import.log').open('w') as log:subprocess.run([godot,'--headless','--path',str(ROOT),'--editor','--quit'],env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
 log=(cache/'scene-import.log').read_text()
 if 'Parse Error' in log or 'Compile Error' in log:raise SystemExit('Scene import failed')
 cmd=[godot,'--path',str(ROOT),'--resolution','1536x864','--disable-vsync','--verbose']
 if a.film:cmd+=['--write-movie',str(cache/(a.tag+'.avi')),'--fixed-fps','30']
 cmd+=['res://'+a.scene]
 if a.film:cmd+=['--','--film','--turns']
 with (out/'run.log').open('w') as log:subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=a.timeout)
 log=(out/'run.log').read_text()
 if 'SCRIPT ERROR' in log or 'ERROR:' in log or 'FAIL ' in log:raise SystemExit('Scene failed: '+str(out/'run.log'))
 print(a.tag,'completed')
