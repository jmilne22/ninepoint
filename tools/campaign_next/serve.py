"""Serve the campaign review with the shared seekable-video handler."""
from pathlib import Path
import importlib.util,argparse
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('range_server',ROOT/'tools/kettle_next/serve.py')
server=importlib.util.module_from_spec(spec);spec.loader.exec_module(server)
p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=8782);a=p.parse_args()
server.serve(ROOT/'docs/campaign_next',a.port)
