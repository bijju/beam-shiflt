class_name PrivacyPolicyText
extends RefCounted
## THE canonical BeamShift Privacy Policy wording. The in-game screen (privacy_policy_screen.gd) renders
## SECTIONS directly; the public web copy (docs/privacy-policy/index.html) is GENERATED from it by
## tools/privacy/build_policy_html.gd - never hand-edit the HTML, edit this file and regenerate.
## A test (test_privacy_policy.gd) fails when the HTML drifts from this text.
##
## Block types inside a section's "blocks": String = paragraph, Array[String] = bullet list,
## {"sub": "text"} = small sub-heading. Every factual claim here was audited against the source
## on 2026-10-03 (see PRIVACY_AUDIT.md); if the game's behaviour changes, change this text with it.

const TITLE := "Privacy Policy"
const GAME := "BeamShift"
const PUBLISHER := "MACLEPRO INC"
const DEVELOPER := "4 Sagez Studios Pvt. Ltd."
const EMAIL := "sage@maclepro.in"
const EFFECTIVE_DATE := "3 October 2026"
const LAST_UPDATED := "3 October 2026"

const SECTIONS := [
	{
		"heading": "1. Summary",
		"blocks": [
			"BeamShift is a laser-reflection puzzle game. This policy explains what information BeamShift stores, what is processed by the third-party services it uses, and the choices you have.",
			[
				"Your game progress and settings are stored on your device only. BeamShift has no player accounts of its own, no BeamShift-operated player server and no cloud save.",
				"On Android, BeamShift asks you to select an age range (12 or younger, 13–17, or 18 or older) the first time you open the game. Only that range is stored, on your device. BeamShift does not send it to any BeamShift server and does not use it to personalise ads.",
				"BeamShift needs an Internet connection to play. Some connections are made by Google and Apple services that BeamShift uses, described below.",
				"BeamShift shows ads through Google AdMob. Because children may play BeamShift, every ad request is treated as child-directed for every player, whatever age range is selected: ads are non-personalised and limited to a general audience rating.",
				"BeamShift sells one optional purchase, No Forced Ads. Payments are handled entirely by Google Play or the Apple App Store.",
				"BeamShift does not use analytics or crash-reporting tools of its own, and does not ask for your contacts, camera, microphone, photos or files, phone number or precise location.",
			],
		],
	},
	{
		"heading": "2. Information stored on your device",
		"blocks": [
			"BeamShift keeps a save file in its private app storage on your device. It contains:",
			[
				"your level progress: completed levels, best move counts and star ratings (campaign, tutorial and procedural levels);",
				"the puzzle you were playing, so you can continue it: tile positions, move count and whether a hint was used;",
				"your settings, such as sound and music on or off;",
				"counters used to space out ads: how many levels you finished since the last ad and when the last full-screen ad was shown;",
				"whether you own the No Forced Ads purchase (a local record of the store's answer);",
				"total play time and the time of the last save;",
				"on Android, the age range you selected (12 or younger, 13–17, or 18 or older). Only the range is stored, never your exact age or date of birth;",
				"on iOS only, if you sign in with Apple: a flag that you are signed in and your name as Apple provided it.",
			],
			"This information stays on your device. MACLEPRO INC and 4 Sagez Studios Pvt. Ltd. do not receive it, cannot see it and cannot restore it. Progress is not shared between devices or between Android and iOS.",
		],
	},
	{
		"heading": "3. Accounts and platform services",
		"blocks": [
			"BeamShift does not ask you to create an account. Signing in to a platform service is optional and the game can be played without it.",
			{"sub": "Android: Google Play Games Services"},
			"On Android, BeamShift asks you to select an age range the first time you open the game (see section 10, Children). What BeamShift does with Google Play Games depends on that choice:",
			[
				"12 or younger: BeamShift's own code does not start Google Play Games sign-in and does not offer a Play Games connection.",
				"13–17 or 18 or older: Google Play Games is optional. BeamShift may check whether you are already signed in to Google Play Games and, if you are, shows your Play Games display name on the Settings and Account screens. You can also choose to connect from the Account screen.",
			],
			"Gameplay, progress, local saves, ads and purchases never require Google Play Games. BeamShift does not use Play Games for cloud save, leaderboards or achievements. Play Games is processed by Google under Google's own terms and privacy policy.",
			"The Google Play Games software library included in the Android app is operated by Google and may run its own checks when the app starts, separately from BeamShift's sign-in screens. Those checks are governed by Google's policies. BeamShift's own code reads only the display name described above.",
			{"sub": "iOS: Sign in with Apple"},
			"On iOS, you may choose Sign in with Apple. BeamShift asks Apple for your name and email address, but only stores a signed-in flag and your name on your device. BeamShift does not store your email address or Apple's sign-in tokens. Apple processes your sign-in under Apple's own terms and privacy policy. You can stop using Sign in with Apple for BeamShift in your Apple account settings.",
		],
	},
	{
		"heading": "4. Network connections",
		"blocks": [
			"BeamShift requires an active Internet connection. While the game is open it regularly makes a small request to a Google connectivity-check address to confirm you are online. Like any Internet request, this exposes your IP address to Google. No game data is sent with it.",
			"Other network connections are made by the services described in this policy: Google AdMob (ads), Google Play Games Services (Android), Google Play Billing and the Apple App Store (purchases), and Sign in with Apple (iOS). BeamShift does not send your game progress to any server.",
		],
	},
	{
		"heading": "5. Advertising",
		"blocks": [
			"BeamShift uses Google AdMob to show two kinds of ads:",
			[
				"Rewarded Hint ads (optional): you choose to request a hint. When a rewarded ad is available, BeamShift first asks you to confirm: the message explains that you will watch a short ad to reveal a hint, and you can choose CANCEL or WATCH AD. A hint is provided when the advertising service reports that the reward requirement has been completed. The No Forced Ads purchase does not remove these optional ads.",
				"Interstitial ads: full-screen ads that can appear at eligible natural breaks between levels, not while you are solving a puzzle, and never during the tutorials. The No Forced Ads purchase removes them.",
			],
			"Because the audience of BeamShift includes children, BeamShift treats every ad request as child-directed for every player, regardless of the age range selected on Android. Each request is tagged as child-directed and as coming from a user under the age of consent, and limited to a general audience (maximum content rating G). The selected age range is not used for advertising, and BeamShift does not enable personalised or adult-targeted ads. Ads are therefore not personalised using your interests, and BeamShift does not show a tracking-permission prompt or use the iOS advertising identifier for tracking.",
			"To deliver and protect ads, Google's advertising software may process technical information from your device, such as your IP address (from which an approximate location can be inferred), device and operating-system details, app information, and how an ad performed, and may use identifiers for purposes such as limiting how often an ad is shown, measurement and fraud prevention. BeamShift's own code does not read the Android advertising ID, and Google's documentation states that the Android advertising ID is not transmitted with ad requests tagged as child-directed. The Android app does include the standard advertising-ID permission that Google's ad software declares. This processing is carried out by Google as described in Google's policies. BeamShift does not receive this information.",
			"Where required, Google's consent tool (User Messaging Platform) may be shown at start-up. If a Privacy Options button appears in Settings, you can use it to review your advertising choices. On Android you can also reset or delete your advertising ID in your device's Google settings.",
		],
	},
	{
		"heading": "6. In-app purchases",
		"blocks": [
			"BeamShift offers one optional one-time purchase, No Forced Ads, which removes the full-screen interstitial ads. It does not remove the optional rewarded Hint ads, which remain available if you choose to use them.",
			"Purchases are processed by Google Play Billing on Android and by the Apple App Store (StoreKit) on iOS. Google and Apple handle your payment details, billing and receipts under their own policies. BeamShift never sees or stores your payment-card details. BeamShift only asks the store whether you own the purchase, and keeps the answer on your device so the purchase can be applied and restored.",
		],
	},
	{
		"heading": "7. Information BeamShift does not directly collect",
		"blocks": [
			"BeamShift does not itself collect, receive or transmit to its own servers:",
			[
				"your name, email address, phone number or postal address (a name shown by Play Games or Apple stays on your device);",
				"your exact age or date of birth (BeamShift asks only for an age range, and keeps it on your device);",
				"your contacts, calendar, camera, microphone, photos, videos or files;",
				"precise (GPS) location;",
				"payment-card or banking details;",
				"chat messages or user-generated content (BeamShift has no chat, social or multiplayer features);",
				"analytics or crash reports sent to the publisher or developer.",
			],
			"Third-party services described in this policy may process technical information as explained above. That processing is controlled by those companies.",
		],
	},
	{
		"heading": "8. Data retention and deletion",
		"blocks": [
			"Because BeamShift stores your game data only on your device, you are in control of it:",
			[
				"Start over in the game: choose New Game from the main menu to reset your main progress (your settings and selected age range are kept).",
				"Delete everything: clear the app's storage in your device settings, or uninstall BeamShift. On iOS, you can also sign out of Sign in with Apple in BeamShift to remove the stored name.",
			],
			"Because there is no BeamShift server holding your data, the publisher and developer cannot delete or recover it for you. Information held by Google or Apple (for example your Play Games profile, purchase history, or advertising data) is kept under their policies and can be managed or deleted in your Google or Apple account settings.",
		],
	},
	{
		"heading": "9. Your privacy rights and choices",
		"blocks": [
			"Depending on where you live, you may have rights over personal information, such as the right to access, correct, delete or restrict its use, or to object to its processing. BeamShift's own data stays on your device, so you can view and delete it yourself as described above.",
			"For information processed by Google or Apple, please use their privacy controls and request tools. You can email us at sage@maclepro.in with any privacy request and we will tell you what we can do and where to go for the rest.",
			[
				"Ads: use the Privacy Options button in Settings when it is shown, and your device's advertising settings.",
				"Sign-in: sign out or disconnect Play Games or Sign in with Apple in your device or account settings at any time; BeamShift keeps working.",
				"Purchases: manage or request refunds through Google Play or the App Store.",
			],
		],
	},
	{
		"heading": "10. Children",
		"blocks": [
			"BeamShift is a general-audience puzzle game that children may play. We do not knowingly collect personal information from children under 13 (or the applicable age of digital consent in your country). BeamShift has no accounts, chat or social features, keeps progress on the device only, and requests child-directed, non-personalised ads for all players.",
			{"sub": "Age range (Android)"},
			"On Android, BeamShift asks you to select an age range the first time you open the game: 12 or younger, 13–17, or 18 or older. BeamShift asks only for a range. It does not ask for or store your exact age, date of birth, name or email address for this purpose.",
			"The selected range is stored only on your device, with your other saved game information. BeamShift does not send it to any BeamShift server or other BeamShift-operated service. It is used only to decide whether optional Google Play Games sign-in is offered (see section 3). It is not used to personalise ads: advertising is child-directed for every player, whichever range is selected. BeamShift asks once and does not currently provide a setting to change the range.",
			"Platform sign-in, ads and purchases are provided by Google and Apple and follow their own age rules. Parents and guardians can use the parental controls of their device and app store, including purchase approval. If you believe a child has provided personal information to us, please contact us at sage@maclepro.in.",
		],
	},
	{
		"heading": "11. Security and international processing",
		"blocks": [
			"Your game data is kept in BeamShift's private storage on your device and is protected by your device's own security. No method of storage or transmission is perfectly secure, so we recommend keeping your device locked and up to date.",
			"Google and Apple operate globally. When they process information for ads, sign-in or purchases, it may be handled in countries other than your own, under their own safeguards and policies.",
		],
	},
	{
		"heading": "12. Third-party services",
		"blocks": [
			"BeamShift uses the following third-party services. Each has its own privacy policy, which applies to the information it processes:",
			[
				"Google AdMob and Google's User Messaging Platform: ads and consent (Google Privacy Policy: policies.google.com/privacy).",
				"Google Play Games Services (Android): optional player sign-in (Google Privacy Policy: policies.google.com/privacy).",
				"Google Play Billing (Android): the No Forced Ads purchase (Google Privacy Policy: policies.google.com/privacy).",
				"Google connectivity check: confirms you are online (Google Privacy Policy: policies.google.com/privacy).",
				"Sign in with Apple (iOS): optional sign-in (Apple Privacy Policy: apple.com/legal/privacy).",
				"Apple App Store / StoreKit (iOS): the No Forced Ads purchase (Apple Privacy Policy: apple.com/legal/privacy).",
			],
		],
	},
	{
		"heading": "13. Changes to this Privacy Policy",
		"blocks": [
			"We may update this Privacy Policy when BeamShift or the services it uses change. The \"Last updated\" date at the top shows when it last changed, and the current version is always available in BeamShift under Settings > Privacy Policy. If a change is significant, we will make it visible in the game or on the store listing before or when it takes effect.",
		],
	},
	{
		"heading": "14. Contact",
		"blocks": [
			"If you have questions about this Privacy Policy or want to make a privacy request, contact:",
			[
				"Publisher: MACLEPRO INC",
				"Developer: 4 Sagez Studios Pvt. Ltd.",
				"Email: sage@maclepro.in",
			],
		],
	},
]
