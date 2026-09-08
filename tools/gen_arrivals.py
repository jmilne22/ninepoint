"""Two tram-window arrival views, drawn at the game's native resolution."""
from pathlib import Path
from coastal_views import arrival


def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    for name,school in [('academy_hall',True),('bondszaal',False)]:arrival(school).save(str(Path(out)/('arrival_'+name+'.png')))
    return 2
if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
