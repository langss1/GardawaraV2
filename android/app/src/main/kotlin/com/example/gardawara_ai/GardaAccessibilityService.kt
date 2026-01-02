package com.example.gardawara_ai

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import android.util.Log
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class GardaAccessibilityService : AccessibilityService() {

    companion object {
        var instance: GardaAccessibilityService? = null
    }

    private var lastScanTime: Long = 0
    private val SCAN_INTERVAL = 3000L

    private val blacklist = listOf(
        "judi", "slot gacor", "toto", "situs gacor", "bandar judi", "taruhan bola", "judi online",
        "888slot", "slot88", "maxwin", "rtp", "pragmatic", "deposit pulsa", "gacor hari ini", 
        "casino", "hoki", "zeus", "login slot", "daftar slot", "bet"
    )

    private val judiRegex = Regex(
        "(?i)\\b(" +
        "[s5\\$][^a-z0-9]*[l1i|!][^a-z0-9]*[o0][^a-z0-9]*[t7]|" +
        "j[^a-z0-9]*[u|v][^a-z0-9]*d[^a-z0-9]*[i1!|]|" +
        "[g96][^a-z0-9]*[a4@][^a-z0-9]*c[^a-z0-9]*[o0][^a-z0-9]*r|" +
        "m[^a-z0-9]*[a4@][^a-z0-9]*x[^a-z0-9]*w[^a-z0-9]*[i1!|][^a-z0-9]*n|" +
        "pr[^a-z0-9]*[a4@][^a-z0-9]*g[^a-z0-9]*m[^a-z0-9]*[a4@][^a-z0-9]*t[^a-z0-9]*[i1!|][^a-z0-9]*c|" +
        "z[^a-z0-9]*[e3][^a-z0-9]*[u|v][^a-z0-9]*[s5\\$]|" +
        "j[^a-z0-9]*[a4@][^a-z0-9]*ck[^a-z0-9]*p[^a-z0-9]*[o0][^a-z0-9]*t|\\bjp\\b" +
        ")\\b"
    )

    // --- LIFECYCLE METHODS ---

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        createNotificationChannel()
        Log.d("GardaService", "✅ Service Connected")
    }

    override fun onInterrupt() {
        Log.d("GardaService", "Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    // --- EVENT HANDLER ---

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: ""

        // 1. FILTER PAKET UTAMA
        if (packageName == "com.android.systemui" || 
            packageName == "com.example.gardawara_ai" ||
            packageName == "com.android.settings") {
            return
        }

        val currentTime = System.currentTimeMillis()
        if (currentTime - lastScanTime < SCAN_INTERVAL) return
        lastScanTime = currentTime

        val rootNode = rootInActiveWindow ?: return

        try {
            // Ambil semua teks untuk dikirim ke Flutter (History/Log)
            val capturedText = getAllText(rootNode)
            if (capturedText.isNotBlank()) {
                sendTextToFlutter(capturedText)
            }

            // 2. LOGIKA KHUSUS CHROME
            if (packageName == "com.android.chrome") {
                if (scanChromeTabContentOnly(rootNode)) {
                    triggerBlocking()
                }
                return 
            }

            // 3. SCAN UMUM (Untuk aplikasi lain)
            if (checkForRestrictedContent(rootNode)) {
                triggerBlocking()
            }
        } finally {
            rootNode.recycle()
        }
    }

    // --- SCANNING LOGIC (GENERAL) ---

    private fun checkForRestrictedContent(node: AccessibilityNodeInfo?): Boolean {
        if (node == null) return false

        if (node.packageName == "com.android.systemui" || 
            node.packageName == "com.example.gardawara_ai") return false

        val textContent = node.text?.toString()?.lowercase() ?: ""
        val descriptionContent = node.contentDescription?.toString()?.lowercase() ?: ""
        val combinedContent = "$textContent $descriptionContent".trim()

        if (combinedContent.isNotBlank()) {
            if (combinedContent.contains("gardawara") || combinedContent.contains("garda wara")) {
                return false
            }

            if (checkText(combinedContent)) {
                Log.d("GardaService", "🚨 TERDETEKSI: $combinedContent")
                return true
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (checkForRestrictedContent(child)) {
                child.recycle()
                return true
            }
            child.recycle()
        }
        return false
    }

    private fun checkText(text: String): Boolean {
        val content = text.lowercase()
        return judiRegex.containsMatchIn(content) || blacklist.any { content.contains(it.lowercase()) }
    }

    // --- SCANNING LOGIC (CHROME SPECIFIC) ---

    private fun scanChromeTabContentOnly(rootNode: AccessibilityNodeInfo): Boolean {
        val contentNodes = rootNode.findAccessibilityNodeInfosByViewId("com.android.chrome:id/compositor_view_holder")
        if (contentNodes.isNotEmpty()) {
            for (node in contentNodes) {
                val found = recursiveContentCheck(node)
                node.recycle()
                if (found) return true
            }
        }
        return findAndScanWebView(rootNode)
    }

    private fun findAndScanWebView(node: AccessibilityNodeInfo): Boolean {
        if (node.className?.contains("RenderWidgetHostView") == true || 
            node.className?.contains("WebView") == true) {
            return recursiveContentCheck(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (findAndScanWebView(child)) {
                child.recycle()
                return true
            }
            child.recycle()
        }
        return false
    }

    private fun recursiveContentCheck(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString()?.lowercase() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase() ?: ""
        val combined = "$text $desc".trim()

        if (combined.isNotBlank() && checkText(combined)) {
            Log.d("GardaService", "🚨 JUDI TERDETEKSI DI KONTEN TAB: $combined")
            return true
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (recursiveContentCheck(child)) {
                child.recycle()
                return true
            }
            child.recycle()
        }
        return false
    }

    // --- BLOCKING ACTION ---

    fun triggerBlocking(): Boolean {
        Handler(Looper.getMainLooper()).post {
            performGlobalAction(GLOBAL_ACTION_BACK)
            Handler(Looper.getMainLooper()).postDelayed({
                performGlobalAction(GLOBAL_ACTION_HOME)
            }, 300)
            
            incrementBlockedCount()
            showBlockingNotification()
            Toast.makeText(applicationContext, "GardaWara: ⛔ JUDI TERDETEKSI!", Toast.LENGTH_LONG).show()
        }
        return true
    }

    // --- UTILITIES ---

    private fun getAllText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        val sb = StringBuilder()
        val text = node.text?.toString() ?: ""
        if (text.isNotBlank()) sb.append(text).append(" ")

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            sb.append(getAllText(child))
            child.recycle()
        }
        return sb.toString().trim()
    }

    private fun incrementBlockedCount() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Konsistensi nama key: flutter.blocked_count
        val currentCount = prefs.getLong("flutter.blocked_count", 0L)
        prefs.edit().putLong("flutter.blocked_count", currentCount + 1).apply()
    }

    private fun showBlockingNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, "GARDA_CHANNEL")
            .setContentTitle("🛡️ GardaWara Beraksi")
            .setContentText("Situs judi berhasil diblokir!")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        notificationManager.notify(1001, notification)
    }

    private fun createNotificationChannel() {
        // Perbaikan: Pastikan urutannya Build.VERSION.SDK_INT dulu baru VERSION_CODES
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "GARDA_CHANNEL",
                "GardaWara Protection",
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun sendTextToFlutter(text: String) {
        Handler(Looper.getMainLooper()).post {
            try {
                // Perbaikan: Memanggil nama variabel yang kita buat di MainActivity tadi
                val messenger = MainActivity.flutterEngineInstance?.dartExecutor?.binaryMessenger
                if (messenger != null) {
                    val channel = MethodChannel(messenger, "com.example.gardawara_ai/accessibility")
                    channel.invokeMethod("onTextDetected", text)
                }
            } catch (e: Exception) {
                Log.e("GardaService", "Gagal kirim ke Flutter: ${e.message}")
            }
        }
    }
}