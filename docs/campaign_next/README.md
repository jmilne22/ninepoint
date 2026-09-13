# Complete campaign graphics preview

ART-15 carries the owner-approved Kettle direction through all twelve maps, twenty-one named/player identities and five existing passerby variants. It remains a session-only preview; normal production launch and saves are unchanged.

From this checkout:

```bash
tools/play_campaign_next.sh             # disposable preview; Continue starts the supplied campaign fixture
tools/play_campaign_next.sh --baseline  # same fixture and original production presentation
DISPLAY_NUM=0 tools/run_campaign_next.sh # repeatable twelve-map tour
python3 tools/build_campaign_next.py    # Blender/Pillow: complete preview build
python3 tools/build_campaign_next.py --people hana sunny
python3 tools/build_campaign_next.py --maps attic academy_study
python3 tools/build_campaign_next.py --surfaces # embedded lesson/review boards
python3 tools/build_assets.py --groups campaign_next --output /home/user/.cache/ninepoint-preview
```

New Game is available in the launcher. Each run uses disposable progress, so closing the game discards that session. The original Kettle-only launcher remains available.

The board has a 1536×600 render target mapped back to its 768×300 logical input area. Character and environment geometry comes from Python-coordinated Blender sources; facial atlases use the original Pillow painter. Production exports are not overwritten. Title and tram-arrival views use the same live upgraded room assets; the opening uses the shared refined board.

Open `http://127.0.0.1:8782/` while the local review server is running. The page includes normal-speed films, matched comparisons and cast sheets. Exact measurements, acceptance evidence and remaining limitations are recorded in [verification.md](verification.md).

The [complete film](campaign-film.mp4) runs 8 minutes 10.5 seconds with four embedded
chapters: environments, cast, locomotion, and Wren's complete game/reaction/review flow.
Individual chapters on the review page retain full 1536×864 resolution. Start the page
again with `python3 tools/campaign_next/serve.py` if its local server has stopped.

On the configured NixOS workstation, build dependencies can be supplied with:

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_campaign_next.py'
```

Review tooling lives in `tools/campaign_next/`: `acceptance.py` runs named routes serially;
`collect.py` captures cast, movement and benchmarks; `package.py` assembles comparison
sheets and a chaptered film (`nix-shell -p ffmpeg 'python3.withPackages (p: [p.pillow])'`);
`media.py` packages individual captured frames and movies;
`serve.py` serves the review on localhost port 8782 with seekable video.
