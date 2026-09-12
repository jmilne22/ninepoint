# Tram 4: Tel Aviv light-rail reference

The owner requested the real TLV light rail's appearance and supplied a three-quarter
street photograph. The production model also uses CRRC's [Red Line vehicle photograph](https://www.crrcma.com/product/lrv-for-israel/)
and its [delivery photographs](https://www.crrcgc.cc/en/2021-07/12/article_F84C1654F8F24A91B3CBEAA13B7C9DB4.html)
as exterior references. These were inspected on 2026-09-12. Reference photos are not
embedded in the game or used as texture maps.

The recognizable features are the white low-floor shell, tall raked wraparound
windscreen, silver headlight belt, paired flush doors, black articulation bellows,
recessed roof ventilation and pantograph. The model has a cab at both ends and five
sections. Its length is compressed for the small game viewport; it is an original Sela
vehicle informed by the reference, not an engineering replica. The small turquoise
lozenge belongs to Sela's presentation and does not reproduce an operator logo.

`tools/ps1/tram_render.py` contains the mesh, material and camera source. The editable
snapshot is `source/tram.blend`. `build_world_art.py --tram` rebuilds just the vehicle;
`--board` and the full asset build include it automatically.

The export is 384×272 at the same 32 pixels per model unit as the street. `tram.json`
records the projected ground origin and five section contact points. Each section has
its own sprite and ground shadow, so the entire vehicle does not inherit a single
sorting point. Both travel directions retain the physical projection instead of
mirroring it horizontally. The existing rail route, platform and boarding timing stay
in place. Boarding cancels a passing tween before taking control of the vehicle.
