package com.example.travel_app

import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.travel_app/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                if (phone != null && message != null) {
                    try {
                        val smsManager: SmsManager = this.getSystemService(SmsManager::class.java)
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success("SMS Enviado")
                    } catch (e: Exception) {
                        result.error("ERR_SMS", e.message, null)
                    }
                } else {
                    result.error("ERR_INVALID_ARGS", "Phone or message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
