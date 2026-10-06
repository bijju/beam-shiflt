class_name AgeGroup
extends RefCounted
## The player's self-selected age RANGE (never an exact age), asked once on Android by the neutral
## age screen and stored only in the local save. It is NOT sent anywhere and it never changes ad
## targeting: every ad request stays child-directed for everyone (AdConfig.CHILD_DIRECTED).
## It only decides whether the optional Google Play Games identity may start.

const UNKNOWN := 0
const CHILD_12_OR_YOUNGER := 1
const TEEN_13_TO_17 := 2
const ADULT_18_PLUS := 3


static func sanitize(value: int) -> int:
	return value if value >= UNKNOWN and value <= ADULT_18_PLUS else UNKNOWN


## The screen is Android-only (Google Play Families); other platforms never see it.
static func screen_required(group: int, os_name: String = OS.get_name()) -> bool:
	return os_name == "Android" and group == UNKNOWN


## Play Games stays OPTIONAL for 13+. UNKNOWN and 12-or-younger never initialise it.
static func play_games_allowed(group: int) -> bool:
	return group == TEEN_13_TO_17 or group == ADULT_18_PLUS
