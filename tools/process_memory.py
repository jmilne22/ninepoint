#!/usr/bin/env python3
"""Sum Linux process-tree RSS, including a steam-run launcher and its engine child."""
import pathlib
import sys


def rss(pid):
    root = pathlib.Path('/proc') / str(pid)
    try:
        fields = dict(line.split(':', 1) for line in (root / 'status').read_text().splitlines())
        own = int(fields.get('VmRSS', '0 kB').split()[0])
        children = (root / 'task' / str(pid) / 'children').read_text().split()
        return own + sum(rss(int(child)) for child in children)
    except (OSError, ValueError):
        return 0


if __name__ == '__main__':
    print(rss(int(sys.argv[1])))
