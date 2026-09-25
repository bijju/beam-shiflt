extends TutorialLevelData
## Tutorial T19 — "Signal Chain". A Receiver -> Remote Emitter chain
## feeding a SWITCH that opens a GATE on the MAIN beam's own path -
## proving a Receiver-triggered chain can gate something else entirely,
## resolved by the same simulate_until_stable() multi-pass machinery
## already used for gates alone (T09). The gate is already open by the
## time the level loads (receiver_states and gate_states both stabilize
## before the player's first tap) - only the Remote Emitter's own beam
## needs routing.

func _init() -> void:
	level_id = 19
	display_name = "Signal Chain"
	grid_width = 8
	grid_height = 7
	tiles = [
		TilePlacement.make_emitter(Vector2i(0, 1), GridTypes.Direction.RIGHT),
		TilePlacement.make_beam_receiver(Vector2i(3, 1), "T19"),
		TilePlacement.make_gate(Vector2i(5, 1), "SG19", false),
		TilePlacement.make_target(Vector2i(7, 1)),

		TilePlacement.make_remote_emitter(Vector2i(0, 4), GridTypes.Direction.RIGHT, "T19"),
		TilePlacement.make_switch(Vector2i(3, 4), "SG19"),
		TilePlacement.make_mirror(Vector2i(5, 4), GridTypes.MirrorOrientation.SLASH),
		TilePlacement.make_target(Vector2i(5, 6)),
	]
	steps = [
		TutorialStepData.message("Receivers can power more than emitters - what they activate can trigger switches too."),
		TutorialStepData.message("This Receiver wakes a Remote Emitter below. Its beam crosses a switch that opens a gate blocking your MAIN beam's path.", Vector2i(3, 1)),
		TutorialStepData.require_tap(Vector2i(5, 4), "Route the Remote Emitter's own beam to its target - the gate above is already open."),
		TutorialStepData.wait_for_solved(""),
		TutorialStepData.message("Receiver, Remote Emitter, Switch, Gate - a whole chain of consequence from one beam."),
	]
