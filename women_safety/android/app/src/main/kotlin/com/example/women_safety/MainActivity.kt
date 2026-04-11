package com.example.women_safety

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import android.telephony.PhoneStateListener
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val TAG = "WomenSafetySMS"
	}

	private val smsChannel = "women_safety/sms"
	private val callChannel = "women_safety/call"
	private val callStateChannel = "women_safety/call_state"
	private var callStateSink: EventChannel.EventSink? = null
	private var telephonyManager: TelephonyManager? = null
	private var legacyPhoneStateListener: PhoneStateListener? = null
	private var modernTelephonyCallback: TelephonyCallback? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, callStateChannel)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					callStateSink = events
					registerCallStateListener()
				}

				override fun onCancel(arguments: Any?) {
					unregisterCallStateListener()
					callStateSink = null
				}
			})

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
			.setMethodCallHandler { call, result ->
					if (call.method != "sendDirectSms" && call.method != "sendDirectSmsBulk") {
					result.notImplemented()
					return@setMethodCallHandler
				}

					val message = call.argument<String>("message").orEmpty()
					if (message.isEmpty()) {
						result.error("INVALID_ARGS", "Message is required", null)
						return@setMethodCallHandler
					}

				val hasPermission = ActivityCompat.checkSelfPermission(
					this,
					Manifest.permission.SEND_SMS,
				) == PackageManager.PERMISSION_GRANTED

				if (!hasPermission) {
					result.error("PERMISSION_DENIED", "SEND_SMS permission not granted", null)
					return@setMethodCallHandler
				}

				try {
					val smsManager = resolveSmsManager()

						if (call.method == "sendDirectSms") {
							val phone = call.argument<String>("phone")?.trim().orEmpty()
							if (phone.isEmpty()) {
								result.error("INVALID_ARGS", "Phone is required", null)
								return@setMethodCallHandler
							}

							val destination = normalizePhoneNumber(phone)
							if (destination.isEmpty()) {
								result.error("INVALID_ARGS", "Invalid phone format", null)
								return@setMethodCallHandler
							}

							val messageParts = smsManager.divideMessage(message)
							smsManager.sendMultipartTextMessage(destination, null, messageParts, null, null)
							result.success(1)
							return@setMethodCallHandler
						}

						val phones = call.argument<List<String>>("phones") ?: emptyList()
						if (phones.isEmpty()) {
							result.error("INVALID_ARGS", "Phones list is required", null)
							return@setMethodCallHandler
						}

						var successCount = 0
						for (phone in phones) {
							if (phone.isBlank()) continue
							val destination = normalizePhoneNumber(phone)
							if (destination.isEmpty()) {
								Log.w(TAG, "Skipping invalid phone: $phone")
								continue
							}

							try {
								val messageParts = smsManager.divideMessage(message)
								smsManager.sendMultipartTextMessage(destination, null, messageParts, null, null)
								successCount++
							} catch (e: Exception) {
								Log.e(TAG, "Failed to send SMS to $destination", e)
							}
						}

						result.success(successCount)
				} catch (e: Exception) {
					Log.e(TAG, "SMS send failed", e)
					result.error("SEND_FAILED", e.message, null)
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callChannel)
			.setMethodCallHandler { call, result ->
				if (call.method != "startDirectCall") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val phone = call.argument<String>("phone")?.trim().orEmpty()
				if (phone.isEmpty()) {
					result.error("INVALID_ARGS", "Phone is required", null)
					return@setMethodCallHandler
				}

				val hasPermission = ActivityCompat.checkSelfPermission(
					this,
					Manifest.permission.CALL_PHONE,
				) == PackageManager.PERMISSION_GRANTED

				if (!hasPermission) {
					result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
					return@setMethodCallHandler
				}

				try {
					val callIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone"))
					callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
					startActivity(callIntent)
					result.success(true)
				} catch (e: Exception) {
					result.error("CALL_FAILED", e.message, null)
				}
			}
	}

	private fun resolveSmsManager(): SmsManager {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
			if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
				return SmsManager.getSmsManagerForSubscriptionId(subId)
			}
		}
		return SmsManager.getDefault()
	}

	private fun normalizePhoneNumber(raw: String): String {
		val trimmed = raw.trim()
		if (trimmed.isEmpty()) {
			return ""
		}

		if (trimmed.startsWith("+")) {
			val cleaned = "+" + trimmed.substring(1).replace(Regex("\\D"), "")
			return cleaned
		}

		val digitsOnly = trimmed.replace(Regex("\\D"), "")
		if (digitsOnly.length == 12 && digitsOnly.startsWith("91")) {
			return "+$digitsOnly"
		}
		return digitsOnly
	}

	private fun registerCallStateListener() {
		val manager = telephonyManager ?: return

		val hasPermission = ActivityCompat.checkSelfPermission(
			this,
			Manifest.permission.READ_PHONE_STATE,
		) == PackageManager.PERMISSION_GRANTED

		if (!hasPermission) {
			callStateSink?.error("PERMISSION_DENIED", "READ_PHONE_STATE permission not granted", null)
			return
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			val callback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
				override fun onCallStateChanged(state: Int) {
					emitCallState(state)
				}
			}
			modernTelephonyCallback = callback
			manager.registerTelephonyCallback(mainExecutor, callback)
			return
		}

		@Suppress("DEPRECATION")
		val listener = object : PhoneStateListener() {
			override fun onCallStateChanged(state: Int, phoneNumber: String?) {
				emitCallState(state)
			}
		}

		legacyPhoneStateListener = listener
		@Suppress("DEPRECATION")
		manager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
	}

	private fun unregisterCallStateListener() {
		val manager = telephonyManager ?: return

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			val callback = modernTelephonyCallback
			if (callback != null) {
				manager.unregisterTelephonyCallback(callback)
				modernTelephonyCallback = null
			}
			return
		}

		val listener = legacyPhoneStateListener
		if (listener != null) {
			@Suppress("DEPRECATION")
			manager.listen(listener, PhoneStateListener.LISTEN_NONE)
			legacyPhoneStateListener = null
		}
	}

	private fun emitCallState(state: Int) {
		val sink = callStateSink ?: return
		val payload = mapOf(
			"state" to when (state) {
				TelephonyManager.CALL_STATE_IDLE -> "IDLE"
				TelephonyManager.CALL_STATE_RINGING -> "RINGING"
				TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
				else -> "UNKNOWN"
			},
			"timestamp" to System.currentTimeMillis(),
		)

		Handler(Looper.getMainLooper()).post {
			sink.success(payload)
		}
	}
}
