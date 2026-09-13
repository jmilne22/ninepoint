"""Serve review media on localhost, including byte ranges for browser video seeking."""
import argparse,re
from pathlib import Path
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
ROOT=Path(__file__).resolve().parents[2]/'docs/kettle_next'
class Preview(SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(ROOT),**kwargs)
    def send_head(self):
        self.remaining=None
        path=Path(self.translate_path(self.path))
        value=self.headers.get('Range','')
        if not path.is_file() or not value:return super().send_head()
        match=re.fullmatch(r'bytes=(\d*)-(\d*)',value)
        if not match or not any(match.groups()):return super().send_head()
        size=path.stat().st_size;a,b=match.groups()
        start=int(a) if a else max(0,size-int(b));end=min(size-1,int(b)) if a and b else size-1
        if start>end or start>=size:
            self.send_error(416);return None
        self.send_response(206)
        self.send_header('Content-Type',self.guess_type(str(path)))
        self.send_header('Accept-Ranges','bytes')
        self.send_header('Content-Range',f'bytes {start}-{end}/{size}')
        self.send_header('Content-Length',str(end-start+1));self.end_headers()
        source=path.open('rb');source.seek(start);self.remaining=end-start+1;return source
    def copyfile(self,source,output):
        try:
            if self.remaining is None:return super().copyfile(source,output)
            while self.remaining:
                chunk=source.read(min(65536,self.remaining))
                if not chunk:break
                output.write(chunk);self.remaining-=len(chunk)
        except (BrokenPipeError,ConnectionResetError):pass
def serve(root,port):
    global ROOT
    ROOT=Path(root)
    ThreadingHTTPServer(('127.0.0.1',port),Preview).serve_forever()

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=8781);args=p.parse_args()
    serve(ROOT,args.port)
