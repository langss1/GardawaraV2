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
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.gardawara_ai/accessibility"
    private var methodChannel: MethodChannel? = null

    companion object {
        var flutterEngineInstance: FlutterEngine? = null
    }

    // GABUNGKAN SEMUA LOGIKA ENGINE DI SINI
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 1. Simpan instance untuk Service
        flutterEngineInstance = flutterEngine

        // 2. Setup MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // 3. Set MethodCallHandler
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    val expectedComponentName = ComponentName(context, GardaAccessibilityService::class.java)
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
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "triggerNativeBlock" -> {
                    val blocked = GardaAccessibilityService.instance?.triggerBlocking()
                    if (blocked == true) {
                        result.success(true)
                    } else {
                        result.error("UNAVAILABLE", "Service Aksesibilitas belum aktif", null)
                    }
                }
                "performGlobalActionBack" -> {
                    val intent = Intent("com.example.gardawara_ai.PERFORM_BACK")
                    context.sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private val textReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val text = intent.getStringExtra("detected_text")
            if (text != null) {
                methodChannel?.invokeMethod("onTextDetected", text)
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
        try {
            unregisterReceiver(textReceiver)
        } catch (e: Exception) {
            Log.e("MainActivity", "Receiver already unregistered")
        }
        flutterEngineInstance = null
    }
}