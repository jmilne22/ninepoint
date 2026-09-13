"""Run selected existing acceptance routes serially, recording failures without hiding them."""
import argparse,os,subprocess,json,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/campaign_next';CACHE=Path.home()/'.cache/ninepoint-campaign-next'
p=argparse.ArgumentParser();p.add_argument('routes',nargs='+');p.add_argument('--film',action='store_true');a=p.parse_args()
results=[]
for route in a.routes:
 folder=OUT/route;folder.mkdir(parents=True,exist_ok=True)
 env={**os.environ,'DISPLAY_NUM':'0','RESOLUTION':'1536x864','OUT':str(folder),'LOG':str(folder/'run.log'),'TIMEOUT':'1200'}
 if a.film:env['MOVIE']=str(CACHE/(route+'.avi'))
 start=time.monotonic()
 with (CACHE/(route+'-runner.log')).open('w') as log:
  result=subprocess.run(['bash','tools/run_campaign_next.sh','tools/autopilot/'+route+'.json'],cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
 results.append({'route':route,'exit':result.returncode,'seconds':round(time.monotonic()-start,2)})
 print(json.dumps(results[-1]),flush=True)
 (folder/'result.json').write_text(json.dumps(results[-1],indent=2)+'\n')
 (OUT/'latest-routes.json').write_text(json.dumps(results,indent=2)+'\n')
 if result.returncode:raise SystemExit(result.returncode)
