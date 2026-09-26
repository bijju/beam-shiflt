# levels/campaign/

The handcrafted 100-level production campaign (10 stages of 10 levels
each — see `ROADMAP.md`), kept physically separate from `levels/` (the
15 development/regression test levels — see `DECISIONS.md` D29) and
`levels/editor_fixtures/` (validator/solver test fixtures).

## Structure

```
levels/campaign/
    stage_01/   Stage 1 — First Light (levels 1-10)     ← populated
    stage_02/   Stage 2 — Reflection (levels 11-20)      ← not yet created
    ...
    stage_10/   Stage 10 — Singularity (levels 91-100)   ← not yet created
```

One `.gd` file per level (`level_01.gd` … `level_10.gd` within each
stage folder), following exactly the same `extends LevelData` /
`_init()` / `TilePlacement.make_*()` pattern as the existing
`levels/level_01.gd` … `level_15.gd` dev levels — see those files, or
any file in `stage_01/`, for the exact shape. Every campaign level sets
`is_campaign_level = true` and `stage = "<Stage Name>"` (matching
`ROADMAP.md`'s stage names exactly) so a level's own data self-identifies
its population regardless of which directory it lives in.

See `CAMPAIGN_DESIGN.md` (project root) for the full architecture: the
100-level structure, mechanic progression per stage, difficulty
philosophy, optimal-move/grid-size guidelines, production-level
acceptance criteria, and the Stage 1 design table. That document is the
main reference for creating every future stage — read it before
authoring Stage 2 onward.

## Do not

- Delete, rename, or overwrite `levels/level_01.gd` … `level_15.gd` —
  those remain the development/regression test population, unrelated to
  this directory, still referenced directly by regression scripts and
  `LevelManager.LEVEL_PATHS`.
- Create Levels 11+ (Stage 2 onward) without being explicitly asked —
  each stage is its own scoped unit of work, validated and reviewed
  before the next begins, same as Stage 1 was.
- Build a procedural/random level generator to populate this directory —
  explicit standing exclusion, see `DECISIONS.md` D30. Every level here
  is, and must remain, handcrafted and individually solver-validated.
