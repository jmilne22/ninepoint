"""Local listening review with seekable media; binds only to localhost."""
from pathlib import Path
import argparse
import importlib.util
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('range_server',ROOT/'tools/kettle_next/serve.py')
server=importlib.util.module_from_spec(spec);spec.loader.exec_module(server)
parser=argparse.ArgumentParser();parser.add_argument('--port',type=int,default=8793)
server.serve(ROOT/'docs/audio_preview',parser.parse_args().port)
