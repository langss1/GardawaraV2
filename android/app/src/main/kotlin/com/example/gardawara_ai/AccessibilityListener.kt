package com.example.gardawara_ai

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

class AccessibilityListener : AccessibilityService() {

    // Receiver untuk menerima perintah "BLOKIR" dari MainActivity (Flutter)
    private val commandReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.example.gardawara_ai.PERFORM_BACK") {
                // Lakukan aksi Back (Keluar dari Chrome)
                performGlobalAction(GLOBAL_ACTION_BACK)
                
                // Opsional: Tekan Home jika Back tidak cukup
                // performGlobalAction(GLOBAL_ACTION_HOME)
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Daftar receiver saat service aktif
        val filter = IntentFilter("com.example.gardawara_ai.PERFORM_BACK")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            registerReceiver(commandReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(commandReceiver, filter)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || rootInActiveWindow == null) return

        // 1. Ambil teks dari layar (URL bar atau konten)
        val extractedText = recursiveReadText(rootInActiveWindow)

        // 2. Kirim ke MainActivity (agar diteruskan ke Flutter)
        if (extractedText.isNotEmpty()) {
            val intent = Intent("com.example.gardawara_ai.SEND_TEXT")
            intent.putExtra("detected_text", extractedText)
            sendBroadcast(intent)
        }
    }

    private fun recursiveReadText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        
        // Optimasi: Hanya baca URL Bar atau Search Box di Chrome
        // ID Chrome URL Bar biasanya: "com.android.chrome:id/url_bar"
        if (node.viewIdResourceName != null && 
           (node.viewIdResourceName.contains("url_bar") || node.viewIdResourceName.contains("search_box"))) {
            return node.text?.toString() ?: ""
        }

        // Jika mau baca seluruh layar (lebih berat tapi lebih akurat), uncomment bawah ini:
        // val sb = StringBuilder()
        // if (node.text != null) sb.append(node.text).append(" ")
        
        var result = ""
        for (i in 0 until node.childCount) {
            result += recursiveReadText(node.getChild(i))
        }
        return result // Ganti dengan sb.toString() jika ingin baca semua
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(commandReceiver)
    }
}