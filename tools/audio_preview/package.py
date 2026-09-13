"""Standalone listening comparisons and compact review media from game captures."""
import argparse
import json
from pathlib import Path
import subprocess
import numpy as np
from dsp import RATE, read, write, normalize, audition_loudness
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/audio_preview'

def sounds():
    OUT.mkdir(parents=True,exist_ok=True)
    pieces=[]; labels=[]
    for family in ['original','snap','thunk','deep']:
        hits=[]
        for i in range(6):
            path=ROOT/'audio'/('stone_place_alt.wav' if i%2 else 'stone_place.wav') if family=='original' else ROOT/'audio_preview'/f'stone_{family}_{i}.wav'
            hit=read(path)
            hit=normalize(hit,OUT/'measure.wav',-24,repeated=True)
            hits.append(np.pad(hit,(0,RATE-len(hit))))
        segment=np.concatenate(hits)
        write(OUT/f'{family}.wav',segment)
        labels.append({'family':family,'start_seconds':len(pieces)*7,'end_seconds':len(pieces)*7+6,'lufs':audition_loudness(hits[0])})
        pieces.append(np.concatenate([segment,np.zeros(RATE)]))
    write(OUT/'stone-comparison.wav',np.concatenate(pieces))
    (OUT/'comparison-timeline.json').write_text(json.dumps(labels,indent=2)+'\n')
    for name in ['capture_single','capture_group','bowl_rattle']:
        write(OUT/f'{name}.wav',read(ROOT/'audio_preview'/f'{name}.wav'))
    for name in ['kettle','match','match_in']:
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(ROOT/'audio_preview'/f'{name}.wav'),'-c:a','libmp3lame','-b:a','192k',str(OUT/f'{name}.mp3')],check=True)

def movie(source,name):
    subprocess.run(['ffmpeg','-v','error','-y','-i',source,'-vf','scale=in_range=pc:out_range=tv,format=yuv420p','-c:v','libx264','-threads','4','-preset','fast','-crf','19','-c:a','aac','-b:a','192k','-movflags','+faststart',str(OUT/f'{name}.mp4')],check=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--movie',nargs=2);args=parser.parse_args()
    if args.movie:movie(*args.movie)
    else:sounds()
