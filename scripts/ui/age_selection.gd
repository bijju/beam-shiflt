extends Control
## First-launch neutral age screen (Android only, Google Play Families). Three equal choices, no default,
## no exact age, nothing transmitted: the range goes to SaveManager (local) and PlatformAccount, which
## then decides whether the OPTIONAL Play Games identity may start. It never changes ad targeting
## (every ad request is child-directed for everyone) and never gates gameplay.

const NEXT_SCENE_PATH := "res://scenes/ui/main_menu.tscn"

@onready var _child_button: Button = %ChildButton
@onready var _teen_button: Button = %TeenButton
@onready var _adult_button: Button = %AdultButton

var _chosen := false


func _ready() -> void:
	_child_button.pressed.connect(_choose.bind(AgeGroup.CHILD_12_OR_YOUNGER))
	_teen_button.pressed.connect(_choose.bind(AgeGroup.TEEN_13_TO_17))
	_adult_button.pressed.connect(_choose.bind(AgeGroup.ADULT_18_PLUS))


func _choose(group: int) -> void:
	# Under the InternetBlocker the tree is paused, but a queued press must still never commit a choice.
	if _chosen or InternetManager.is_blocking():
		return
	_chosen = true
	AudioManager.play_ui_button_press()
	SaveManager.set_age_group(group)
	PlatformAccount.apply_age_group()
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


## A choice is required; Back neither skips nor quits from here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		return
