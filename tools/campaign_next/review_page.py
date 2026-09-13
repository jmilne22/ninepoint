"""Build a local review index over verified, real-renderer artifacts."""
from pathlib import Path
from html import escape
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/campaign_next'
page='''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ninepoint — campaign graphics review</title><style>
body{margin:0;background:#eee7d8;color:#243e33;font:17px/1.5 system-ui}main{max-width:1200px;margin:auto;padding:42px 24px}h1{font-size:42px;margin:0}h2{margin-top:42px}p{max-width:820px}video,img{width:100%;border-radius:10px;background:#233d34}video{max-height:720px}nav{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0}a,button{color:#224837}nav a,button{padding:9px 15px;border:1px solid #819383;border-radius:8px;background:#faf4e7;text-decoration:none;cursor:pointer}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.small{font-size:14px}code{background:#e0d8c5;padding:3px 6px}details{margin:24px 0}summary{cursor:pointer;font-size:21px;font-weight:600}@media(max-width:700px){.grid{grid-template-columns:1fr}h1{font-size:32px}}</style></head><body><main>
<p>NINEPOINT / CAMPAIGN PRESENTATION PREVIEW</p><h1>The rest of Sela, brought together.</h1><p>The approved Kettle direction across twelve environments, the complete cast, and a cleaner board. All footage below is captured in Godot and plays at normal speed.</p>
<nav><a href="#world">Environments</a><a href="#cast">Characters</a><a href="#movement">Movement</a><a href="#match">Wren match</a><a href="#compare">Before / after</a><a href="verification.md">Verification record</a></nav>
<p class="small">Play from this checkout: <code>tools/play_campaign_next.sh</code>. Disposable saves; production remains unchanged. The baseline option uses the same starting fixture. <a href="campaign-film.mp4">Download the complete chaptered film.</a></p>
'''
for ident,title,src in [('world','All twelve environments','environments'),('cast','Complete cast: construction and motion','cast'),('movement','Walking, jogging, turning and stopping','movement'),('match','A real Wren match, reaction and review','wren-match')]:
 stamp=int((OUT/(src+'.mp4')).stat().st_mtime) if (OUT/(src+'.mp4')).exists() else 0
 poster={'world':'campaign/14_novice_from_hall.png','cast':'cast/body_01_000.png','movement':'movement/run_4.png','match':'kettle_next/10_match_ready.png'}[ident]
 page+=f'<section id="{ident}"><h2>{title}</h2><video id="{ident}-video" controls preload="metadata" poster="{poster}" src="{src}.mp4?v={stamp}"></video>'
 if ident=='match':
  import re
  log=OUT/'kettle_next/run.log'
  if log.exists():
   beats=re.findall(r'MOVIE BEAT: (.*?) frame=(\d+)',log.read_text())
   page+='<nav>'
   seen=set()
   for label,frame in beats:
    if label in seen:continue
    seen.add(label)
    if label in ['room','tomas','kesh','wren','match_ready','counting','result','reaction_before_review','review_loading','review_graph','back_in_room','walking_after_review']:
     page+=f'<button onclick="document.getElementById(\'match-video\').currentTime={int(frame)/30:.2f}">{escape(label.replace("_"," "))}</button>'
   page+='</nav>'
 page+='</section>'
page+='<section id="compare"><h2>Matched environments</h2><p>Each comparison uses the same map, arrival point and gameplay camera. Current main is on the left; the campaign preview is on the right.</p>'
for file in sorted((OUT/'comparisons').glob('*.jpg')):
 label=file.stem[3:] if file.stem[:2].isdigit() else file.stem
 page+=f'<details><summary>{escape(label.replace("_"," "))}</summary><img loading="lazy" src="comparisons/{file.name}"></details>'
page+='</section><h2>Character inspection</h2><div class="grid">'
for file in sorted(OUT.glob('*sheet.jpg')):
 if file.name in ['environments-sheet.jpg','boards-sheet.jpg','capture-sheet.jpg','environment-sheet.jpg']:continue
 page+=f'<a href="{file.name}"><img loading="lazy" src="{file.name}" alt="{escape(file.stem)}"></a>'
page+='</div><p class="small">Source geometry: Blender. Painted facial atlases: Pillow, preserving the original expressions. No AI illustration assets. See the verification record for measured performance and remaining limitations.</p></main></body></html>'
(OUT/'index.html').write_text(page)
