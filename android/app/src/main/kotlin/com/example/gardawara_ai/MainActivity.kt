package com.example.gardawara_ai  

import android.content.BroadcastReceiver
import android.content.ComponentName  
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils       
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.gardawara_ai/accessibility"
    private var methodChannel: MethodChannel? = null

    // Receiver untuk menerima teks dari Accessibility Service
    private val textReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val text = intent.getStringExtra("detected_text")
            if (text != null) {
                methodChannel?.invokeMethod("onTextDetected", text)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    // Cek apakah service sudah aktif atau belum
                    val expectedComponentName = ComponentName(context, AccessibilityListener::class.java)
                    val enabledServicesSetting = Settings.Secure.getString(
                        context.contentResolver,
                        Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    ) ?: ""
                    val colonSplitter = TextUtils.SimpleStringSplitter(':')
                    colonSplitter.setString(enabledServicesSetting)
                    var isEnabled = false
                    while (colonSplitter.hasNext()) {
                        val componentNameString = colonSplitter.next()
                        val enabledComponent = ComponentName.unflattenFromString(componentNameString)
                        if (enabledComponent != null && enabledComponent == expectedComponentName) {
                            isEnabled = true
                            break
                        }
                    }
                    result.success(isEnabled)
                }
                "requestAccessibilityPermission" -> {
                    // INI YANG KURANG SEBELUMNYA: Buka halaman Settings Aksesibilitas
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "performGlobalActionBack" -> {
                    // Kirim perintah ke Accessibility Service
                    val intent = Intent("com.example.gardawara_ai.PERFORM_BACK")
                    context.sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter("com.example.gardawara_ai.SEND_TEXT")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            registerReceiver(textReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(textReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(textReceiver)
    }
}