// GodotGoogleSignIn plugin.
//
// Corrected against live official docs during the Phase 4A resume pass (2026-09-28):
// developer.android.com/identity/sign-in/credential-manager-siwg-implementation
// confirms a dedicated "Continue with Google" BUTTON flow should use
// GetSignInWithGoogleOption (not GetGoogleIdOption, which is for Credential Manager's
// own auto/bottom-sheet UI) - this file now uses GetSignInWithGoogleOption. A nonce is
// generated per attempt (recommended, not required, by the same doc) to guard against
// replay. GodotPlugin's `activity` property (Kotlin-synthesized from the Java
// GodotPlugin.getActivity() method) was confirmed correct against
// github.com/godotengine/godot's GodotPlugin.java - the previous pass's uncertainty
// about this accessor is resolved.
//
// STILL NOT COMPILED IN THIS PASS - the resume session's own command-execution
// environment was confirmed live (git status/log ran), but this pass has not yet run
// Gradle. See README.md in this folder for exact status once that step runs.

package com.foursagez.beamshift.googlesignin

import android.util.Base64
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.security.SecureRandom

/**
 * Wraps Android's Credential Manager (Sign in with Google, button flow) to hand
 * GDScript a Google ID token, which FirebaseAuth.sign_in_with_google_id_token() then
 * exchanges via Firebase's accounts:signInWithIdp REST endpoint. This plugin does NOT
 * talk to Firebase itself - it only ever produces an ID token or a failure/cancel
 * reason. Never logs the ID token itself, only that one arrived.
 *
 * GDScript usage (scripts/ui/account_screen.gd):
 *   var plugin = Engine.get_singleton("GodotGoogleSignIn")
 *   if plugin.call("isAvailable"):
 *       plugin.call("signIn", FirebaseConfig.GOOGLE_WEB_CLIENT_ID)
 *   -> "google_id_token_obtained" (String) / "google_sign_in_cancelled" () /
 *      "google_sign_in_failed" (String reason)
 */
class GoogleSignInPlugin(godot: Godot) : GodotPlugin(godot) {

	private val scope = CoroutineScope(Dispatchers.Main)

	override fun getPluginName(): String = "GodotGoogleSignIn"

	override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
		SignalInfo("google_id_token_obtained", String::class.java),
		SignalInfo("google_sign_in_cancelled"),
		SignalInfo("google_sign_in_failed", String::class.java),
	)

	/**
	 * Cheap, synchronous availability check - lets the caller (account_screen.gd) hide/
	 * disable the button instead of letting a tap fail. Credential Manager itself needs
	 * no separate "is available" call; this only confirms the plugin/Activity are
	 * present, which is the one thing that can be checked without actually launching
	 * the UI.
	 */
	@UsedByGodot
	fun isAvailable(): Boolean = activity != null

	/**
	 * Launches the Credential Manager Google Sign-In (button) flow. Always resolves via
	 * exactly one of the three plugin signals - never throws back into GDScript, never
	 * blocks the caller (runs on a coroutine).
	 *
	 * @param serverClientId MUST be the Web OAuth client id (FirebaseConfig.
	 *   GOOGLE_WEB_CLIENT_ID), never the Android client id - Firebase verifies the ID
	 *   token's audience against the Web client id.
	 */
	@UsedByGodot
	fun signIn(serverClientId: String) {
		Log.i(TAG, "[GoogleSignIn] signIn() called.")
		val activityRef = activity
		if (activityRef == null) {
			Log.w(TAG, "[GoogleSignIn] No activity available - cannot start Credential Manager.")
			emitSignal("google_sign_in_failed", "NO_ACTIVITY")
			return
		}
		scope.launch {
			try {
				val credentialManager = CredentialManager.create(activityRef)
				val signInWithGoogleOption = GetSignInWithGoogleOption.Builder(serverClientId)
					.setNonce(generateSecureRandomNonce())
					.build()
				val request = GetCredentialRequest.Builder()
					.addCredentialOption(signInWithGoogleOption)
					.build()
				Log.i(TAG, "[GoogleSignIn] Native credential request started.")
				val result = credentialManager.getCredential(activityRef, request)
				val credential = result.credential
				Log.i(TAG, "[GoogleSignIn] Native credential request returned. type=${credential.type}")
				if (credential is CustomCredential &&
					credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
				) {
					val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
					Log.i(TAG, "[GoogleSignIn] Google ID token obtained: YES")
					emitSignal("google_id_token_obtained", googleIdTokenCredential.idToken)
				} else {
					Log.w(TAG, "[GoogleSignIn] Google ID token obtained: NO - unexpected credential type ${credential.type}")
					emitSignal("google_sign_in_failed", "UNEXPECTED_CREDENTIAL_TYPE")
				}
			} catch (e: GetCredentialCancellationException) {
				// Reported separately from a real failure - the player just dismissed
				// the account chooser, not an error worth surfacing as one.
				Log.i(TAG, "[GoogleSignIn] Cancelled by the user.")
				emitSignal("google_sign_in_cancelled")
			} catch (e: GetCredentialException) {
				// e.type is Credential Manager's own stable reason string - never log
				// e.message, which can include account-identifying details. The
				// exception CLASS is also logged: this is the boundary that fires when
				// Google's backend rejects the calling app's package+signing-certificate
				// (e.g. no matching Android OAuth client for this SHA-1) - a console
				// config gap, not a code bug, shows up here as a GetCredentialException.
				Log.w(TAG, "[GoogleSignIn] Native credential request FAILED before a credential was returned. exceptionClass=${e.javaClass.name} type=${e.type}")
				emitSignal("google_sign_in_failed", e.type ?: "UNKNOWN")
			} catch (e: GoogleIdTokenParsingException) {
				Log.w(TAG, "[GoogleSignIn] Failed to parse Google ID token credential. exceptionClass=${e.javaClass.name}")
				emitSignal("google_sign_in_failed", "PARSE_FAILED")
			} catch (e: Exception) {
				// Previously logged only a generic message with no way to tell WHAT
				// exception actually fired - this is the one change most likely to turn
				// an unhelpful logcat capture into a diagnosable one, at zero PII risk
				// (class name + message-less summary only, never e.message which can
				// carry account details for some exception types).
				Log.w(TAG, "[GoogleSignIn] Unexpected exception. exceptionClass=${e.javaClass.name}")
				emitSignal("google_sign_in_failed", "UNKNOWN:" + e.javaClass.simpleName)
			}
		}
	}

	private fun generateSecureRandomNonce(byteLength: Int = 32): String {
		val randomBytes = ByteArray(byteLength)
		SecureRandom().nextBytes(randomBytes)
		return Base64.encodeToString(randomBytes, Base64.NO_WRAP or Base64.URL_SAFE or Base64.NO_PADDING)
	}

	companion object {
		private const val TAG = "GodotGoogleSignIn"
	}
}
