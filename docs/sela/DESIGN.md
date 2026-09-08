# Sela: a coastal neighborhood for Ninepoint

The approved direction is a fictional city inspired by Tel Aviv's everyday streets:
warm, worn and leafy, with a walking neighborhood and a tram to the Go institute.
Every portrait, character identity, walking sheet and activity sheet is preserved.

## What the references contributed

These photographs were opened and inspected during planning. They are reference material;
none is incorporated into the game or redistributed in this repository.

| Reference | Useful visual information | Translation into the game |
|---|---|---|
| [Rothschild coffee kiosk, Time Out](https://www.timeout.com/israel/restaurants/rothschild-coffee-kiosk) — [2048×1536 photo](https://media.timeout.com/images/103613109/image.jpg) | Small kiosk within a planted, inhabited boulevard | Garden tables, tree shade and a modest awning kiosk beside the walking route |
| [Liebling House, Greyscape](https://www.greyscape.com/liebling-haus-tel-aviv/) — [1000×667 photo](https://www.greyscape.com/wp-content/uploads/2020/01/Liebling-House-Image-via-Sharon-Golan-Yaron-.jpg) | Pale plaster, deep horizontal balconies and shutters | Broad facade shapes, recessed balconies, teal shutters and institute windows |
| [Levinsky street, Time Out](https://timeout.co.il/לוינסקי-ב/) — [2000×1125 photo](https://medias.timeout.co.il/www/uploads/2022/10/Levinski01-2000x1125.jpg) | Close shopfronts, awnings and ordinary street activity | Three recognizable neighborhood thresholds and warm, slightly mismatched finishes |
| [Central Beach Promenade, Mayslits Kassif Roytman](https://mkarchitects.com/tel-avivs-central-beach-promenade-2/) — [1920×1080 photo](https://mkarchitects.com/wp-content/uploads/2019/08/026.jpg) | An open sea edge with places to sit and pause | A quiet Sea Walk, shaded bench and a return through the Arcade |

The aim is the relationship between shade, buildings and shared space, rather than a
literal map of Tel Aviv. Sela preserves the original cast and avoids attaching invented
institutions or biographies to real locations. Existing photography rights remain with
their owners; use the source pages when acquiring any production photography.

## Why depart from Verhaven

The former design opposed a formal institution above ground to authentic play below.
That made the institute's architecture colder than Hana and Marguerite's actual writing.
The new design gives the bar, institute and laundry three equally welcoming roles:
patient practice, organized learning and everyday company. Competition remains honest.

A small neighborhood suits the game's strongest loop: meet someone, sit down, play,
hear their reaction, and return. Market Lane → Sea Walk → Arcade → Market Lane now works
in either direction. It gives the review noticeboard a useful place along a return walk,
without adding errands, rewards, a clock or another progression system.

The Pokémon TCG / Tag Force inspiration in the design documents still provides the
structural model: walk around, talk, play, see the record climb and enter a tournament.
M37 explains why clocks and parallel progression were cut; M45 explains the supported
beginner journey. The setting change follows those decisions and makes the shared spaces
more inviting without expanding the mechanical burden.

## Spatial and visual rules

- Twelve maps retain their internal IDs. Market Lane contains the Boulevard Garden;
  The Kettle, Laundry and Rooftop Room retain their familiar entrances. Tram 4 stays west.
- Pale plaster and paving provide a quieter field around people and wooden boards.
  Teal shutters, coral awnings and olive foliage identify places without a new UI vocabulary.
- Market Lane has tall, distinct facade silhouettes; The Kettle has low furniture and
  open shutters; the institute has a planted central court and clear room approaches.
- Sea Walk keeps a large, calm water surface. Its shelter is offset from the arrival
  steps so the player never appears to enter on a pergola roof.
- Animation stays local: foliage tips, awning fringe and sea ripples. There is one sky
  and no simulated time. Synthesized breeze/surf replace the exterior rain beds.
- All raster art and sound remain deterministic Python output. `coastal_palette.py`
  adds environment colors without changing shared portrait, sprite or Go-board colors.

## What remains the same

Capture Go with Pip comes first. Wren's rules, finishing and supported first full game
lead to Kesh's provisional card. Hana's welcome, the novice league and Beginner Cup
remain the journey. Returning to town still offers practice, lessons and game review.
Ranks, engine profiles, head-to-head records, lesson positions and league rules are unchanged.

Legacy saves retain their map, named spawn and all progression. The first load of a save
without the new layout revision discards its exact pixel position and uses the safe named
spawn, avoiding furniture added in the redesign. New saves retain exact positions normally.

The implementation and inspected evidence are recorded in [PLAYTEST.md](PLAYTEST.md).
Independent beginner testing remains necessary for difficulty and unaided wayfinding;
automation does not establish either.


## Tram reference follow-up

The owner supplied a photograph of a modern white articulated light-rail train after
reviewing Sela. Tram 4 now adopts its long, low body, dark glazing, rounded cabs, flexible
joints and roof equipment in original Python pixel art. The sprite grows from 96×36 to
160×36 while the stop, timetable-free service and destination choices remain the same.
The photograph is a reference only and is not included as a game asset.


## Tree correction — SELA-05

The first trees used overlapping shaded ovals. Reusing tree-shaped potted plants on
balconies and the arch made them look suspended; the title's tree was actually placed
above a roof. Those were composition mistakes, not a feature of the intended city.

The replacement follows the boulevard ficus: a pale branching trunk, a broad uneven
crown and dense dark leaves. [Visit Tel Aviv identifies the ficus trees on Rothschild](https://www.visit-tel-aviv.com/en/rothschild-blvd/).
[Sambach's Rothschild photograph](https://commons.wikimedia.org/wiki/File:Ficus_in_Rothschild_Boulevard.JPG)
was opened and visually inspected for the trunk, branch forks and canopy silhouette.
[Tel Aviv University's Ficus Avenue](https://en-lifesci.tau.ac.il/botanical/garden/ficus)
provides local botanical context. The art is a stylized boulevard ficus, not a botanical
identification of the photograph to species. No reference photograph is incorporated
into the generated sprite.

Trees remain grounded in the boulevard garden and the arrival-view pavement. Roof,
balcony, façade and arch greenery is removed. Remaining room/entrance pots have short
strap-shaped foliage. The existing trunk footprints, walking routes, cast, portraits,
tram and Go behavior are preserved.


## Stop correction — SELA-06

The small blue box and single sign tile did not communicate a comfortable light-rail stop.
The replacement uses the shallow cantilever roof, glazed wind screens, integrated seats
and ticket-machine column visible in [IM Segev's Jerusalem project photographs](https://www.imsegev.co.il/project/jlrt-%D7%A8%D7%9B%D7%91%D7%AA-%D7%A7%D7%9C%D7%94-%D7%99%D7%A8%D7%95%D7%A9%D7%9C%D7%99%D7%9D/).
The supplier's 1080×1080 photograph was opened, as was a street photograph in
[Mynet's July 16, 2025 report](https://jerusalem.mynet.co.il/local_news/article/bkquv0nixe).
That report distinguishes existing pale shelters from newer black versions; the inspected
pale-shelter photo corroborates the form. These are dated references checked on September
8, 2026, not a claim to have live imagery of every stop today.

[Cfir's current ticket-machine leaflet](https://www.cfir.co.il/en/files/A5_EN_new.pdf)
confirms platform ticket machines. [NTA's Red Line station information](https://www.nta.co.il/en/light-rail/red-line/ben-gurion/)
confirms prominent platform route/destination displays. For Sela, a clear route number
replaces a real-time display, and the machine is only scenery: no fare or clock is added.
All reference images remain external; the exported game art is original Python drawing.

The pale roof and teal sign fit Sela and keep the shelter distinct from the shopfront.
The canopy grows to 64×48 while its collision footprint stays unchanged. The marked
80×32 platform reaches the rail edge, with a tactile strip along its front. Standing
anywhere inside it offers boarding, without aiming at the pole. Facing a nearby person
or notice still takes priority. The first narrow version failed a turning-at-the-edge
play check; extending the actual platform provides the space the interaction needs.
