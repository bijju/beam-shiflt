extends TutorialLevelData
## Tutorial T09 — "Switch and Gate". Teaches three linked mechanics in
## one clean route: a SWITCH doesn't block/bend the beam, just crossing
## it opens a linked GATE elsewhere (gates are stateless/derived fresh
## every simulation pass - see DECISIONS.md "Switch/gate simulation
## strategy"); a closed gate blocks like a blocker; and a HAZARD makes
## the puzzle permanently unsolvable if the beam ever touches it, though
## play is never interrupted. All three are real, unmodified LaserSystem
## rules (proven by dev regression level 11 "Switch and Gate" and level
## 12 "Danger Zone").

func _init() -> void:
	level_id = 9
	display_name = "Switch and Gate"
	grid_width = 5
	grid_height = 5
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 2), GridTypes.Direction.RIGHT),
		TilePlacement.make_switch(Vector2i(2, 2), "g1"),
		TilePlacement.make_mirror(Vector2i(3, 2), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_hazard(Vector2i(3, 1)),
		TilePlacement.make_gate(Vector2i(3, 3), "g1", false),
		TilePlacement.make_target(Vector2i(3, 4)),
	]
	steps = [
		TutorialStepData.message("Three new pieces this time: a switch, a gate, and a hazard."),
		TutorialStepData.message("This is a switch. It doesn't block or bend the beam - just crossing it opens a linked gate somewhere else on the board.", Vector2i(2, 2)),
		TutorialStepData.message("This gate starts closed and blocks the beam like a wall - until its linked switch is triggered.", Vector2i(3, 3)),
		TutorialStepData.message("This is a hazard. If the beam ever touches it, the puzzle can never be solved - even though you can keep playing. Route around it, not through it.", Vector2i(3, 1)),
		TutorialStepData.require_tap(Vector2i(3, 2), "Tap this mirror to send the beam down, through the gate the switch already opened - not up, toward the hazard."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Switch opened the gate, and the hazard stayed untouched. Three mechanics, one clean route."),
	]
