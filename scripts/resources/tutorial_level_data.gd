class_name TutorialLevelData
extends LevelData
## A guided tutorial level. Extends LevelData exactly like a campaign
## level - `tiles`/`grid_width`/`grid_height` are simulated by the SAME
## LaserSystem/GridManager, so a tutorial never behaves differently from
## Campaign for the same board (see CLAUDE.md rule 1 and DECISIONS.md
## "Guided tutorial system"). The only addition is `steps`, interpreted
## exclusively by TutorialManager.
##
## `optimal_moves`/`is_campaign_level` are inherited but unused by
## tutorials - a tutorial's own `steps` array is what drives completion,
## not the solver-vs-declared-moves workflow campaign levels use.

## Ordered guided-tutorial steps. TutorialManager.advance() walks this
## array; running past the end finishes the tutorial.
@export var steps: Array[TutorialStepData] = []
