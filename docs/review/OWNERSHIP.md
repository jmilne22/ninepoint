# Ownership ordering verification

The packaged `packaging/katago/bin/README.txt` identifies KataGo v1.15.0 and links
its analysis protocol. The packaged analysis example and production analysis config
both specify `reportAnalysisWinratesAs = BLACK`.

[Version-pinned analysis documentation](https://github.com/lightvector/KataGo/blob/v1.15.0/docs/Analysis_Engine.md)
specifies row-major ownership from top left to bottom right. On 9×9 this is
A9..J9, A8..J8, through A1..J1. `GoBoard.idx(x,y) = y * size + x` uses the same
order. The single conversion validates and copies; it must not flip GTP row labels.

Before implementing the conversion, the actual bundled CPU engine was queried with
Japanese rules, komi 5.5, eight visits, ownership on and policy off. Each query had
one initial stone and the opposing colour to move. Three queries completed in 4.87 s.

| Position | Ownership at correct index | Transposed index | Row-flipped index |
| --- | --- | --- | --- |
| Black A1 | index 72: +0.087786 | index 8: −0.115146 | index 0: −0.154684 |
| Black B3 | index 55: +0.585237 | index 15: +0.061539 | index 19: −0.013093 |
| White B3 | index 55: −0.648008 | index 15: +0.179072 | index 19: −0.054924 |

All arrays contained 81 entries. B3 adds an off-diagonal check with a clearer signal
than the weak A1 stone. The White run establishes sign, not exact colour symmetry:
komi and finite search make engine estimates differ. Deterministic unit fixtures
negate Black-positive values to test exact player-relative equivalence.
