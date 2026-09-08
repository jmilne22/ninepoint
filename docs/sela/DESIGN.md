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
| [Liebling House, Greyscape](https://www.greyscape.com/liebling-haus-tel-aviv/) — [1000×667 photo](https://www.greyscape.com/wp-content/uploads/2020/01/Liebling-House-Image-via-Sharon-Golan-Yaron-.jpg) | Pale plaster, deep horizontal balconies and shutters | Broad facade shapes, recessed teal shutters, planted balconies and institute windows |
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
