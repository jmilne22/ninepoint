#!/usr/bin/env python3
"""Serial, disposable captures using the actual Godot renderer at normal speed."""
import argparse,fcntl,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--profile',choices=['baseline','prototype','both'],default='both')
p.add_argument('--kind',choices=['cast','motion','performance'],required=True);p.add_argument('--film-only',action='store_true');a=p.parse_args()
cache=Path.home()/'.cache/ninepoint-kettle-next';cache.mkdir(parents=True,exist_ok=True)
godot=os.environ.get('GODOT',str(Path.home()/'.local/bin/godot'))
with open('/tmp/ninepoint-run.lock','w') as lock,tempfile.TemporaryDirectory(prefix='capture-',dir=cache) as data:
    fcntl.flock(lock,fcntl.LOCK_EX)
    env={**os.environ,'XDG_DATA_HOME':data,'DISPLAY':os.environ.get('DISPLAY',':0')}
    with (cache/'capture-import.log').open('w') as log:
        subprocess.run([godot,'--headless','--path',str(ROOT),'--editor','--quit'],env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
    imported=(cache/'capture-import.log').read_text()
    if 'Parse Error' in imported or 'Compile Error' in imported: raise SystemExit('Capture import failed; see capture-import.log')
    for profile in ['baseline','prototype'] if a.profile=='both' else [a.profile]:
        if profile=='prototype':env['NINEPOINT_PRESENTATION']='kettle_next'
        else:env.pop('NINEPOINT_PRESENTATION',None)
        scene={'cast':'tools/kettle_next/gallery.tscn','motion':'tools/expressive_world/motion_review.tscn','performance':'tools/kettle_next/benchmark.tscn'}[a.kind]
        env['OUT']=str(ROOT/'docs/kettle_next'/(profile+'-'+a.kind if a.kind!='performance' else 'performance'))
        for filming in ([True] if a.film_only else [False,True] if a.kind!='performance' else [False]):
            tag=f'{profile}-{a.kind}'+('-film' if filming else '')
            cmd=[godot,'--path',str(ROOT),'--resolution','1536x864','--disable-vsync']
            if filming:cmd+=['--write-movie',str(cache/(profile+'-'+a.kind+'.avi')),'--fixed-fps','30']
            cmd+=['res://'+scene]
            if filming:cmd+=['--','--film']+(['--turns'] if a.kind=='motion' else [])
            with (cache/(tag+'.log')).open('w') as log:
                subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=180)
            print(tag,'complete',flush=True)
