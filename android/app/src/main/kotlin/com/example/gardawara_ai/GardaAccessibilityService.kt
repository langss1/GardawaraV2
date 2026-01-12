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
        var isProtectionActive: Boolean = true
        
        private val JUDI_REGEX = Regex(
            "(?i)\\b(" +
            "[s5\\$][\\W_]{0,2}[l1i|!][\\W_]{0,2}[o0][\\W_]{0,2}[t7]|" +
            "j[\\W_]{0,2}[u|v][\\W_]{0,2}d[\\W_]{0,2}[i1!|]|" +
            "[g96][\\W_]{0,2}[a4@][\\W_]{0,2}c[\\W_]{0,2}[o0][\\W_]{0,2}r|" +
            "m[\\W_]{0,2}[a4@][\\W_]{0,2}x[\\W_]{0,2}w[\\W_]{0,2}[i1!|][\\W_]{0,2}[n]|" +
            "pr[\\W_]{0,2}[a4@][\\W_]{0,2}g[\\W_]{0,2}m[\\W_]{0,2}[a4@][\\W_]{0,2}t[\\W_]{0,2}[i1!|][\\W_]{0,2}c|" +
            "z[\\W_]{0,2}[e3][\\W_]{0,2}[u|v][\\W_]{0,2}[s5\\$]|" +
            "j[\\W_]{0,2}[a4@][\\W_]{0,2}ck[\\W_]{0,2}p[\\W_]{0,2}[o0][\\W_]{0,2}t|\\bjp\\b" +
            ")\\b"
        )
    }

    private var lastScanTime: Long = 0
    private val SCAN_INTERVAL = 500L // 0.5 detik (Agresif)
    private val debounceHandler = Handler(Looper.getMainLooper())
    private var pendingBlockRunnable: Runnable? = null
    private var currentActivePackage: String = "" // Pastikan CamelCase sesuai deklarasi
    
    private var chromeAppLaunchTime: Long = 0
    private val CHROME_SAFETY_DELAY = 500L // 0.5 detik (Agresif)

    private val browserPackages = setOf(
        "com.android.chrome",
        "org.mozilla.firefox",
        "com.sec.android.app.sbrowser",
        "com.microsoft.emmx",
        "com.opera.browser",
        "com.opera.mini.native",
        "com.ucmobile.intl",
        "com.brave.browser",
        "com.duckduckgo.mobile.android"
    )

    private val excludedApps = setOf(
        "com.whatsapp", "com.whatsapp.w4b", "com.facebook.katana",
        "org.telegram.messenger", "com.instagram.android", "com.android.systemui",
        "com.example.gardawara_ai", "com.android.settings",
        "com.google.android.inputmethod.latin"
    )

    private val blacklist = listOf(
        "judi online", "situs gacor", "bandar judi", "taruhan bola", 
        "888slot", "slot88", "deposit pulsa tanpa potongan"
    )
    
    private val combinedBlacklistRegex = Regex("(?i)\\b(${blacklist.joinToString("|") { Regex.escape(it) }})\\b")

    private val placeholderTexts = setOf(
        "search google", "type url", "telusuri", "ketik alamat", "cari atau", "google",
        "ai mode", "incognito", "daytrans", "gemini", "beranda", "tab baru", 
        "mulai penelusuran suara", "start voice search", "search or type web address",
        "suggested items", "trending searches", "refine:", "penelusuran populer",
        "saran pencarian", "item yang disarankan"
    )

    private val ignoredViewIds = setOf(
        "com.android.systemui", "com.google.android.inputmethod.latin",
        "navigationBarBackground", "statusBarBackground",
        "com.android.chrome:id/tile_view_title",
        "com.android.chrome:id/content_suggestions",
        "com.android.chrome:id/search_box_text",
        "com.android.chrome:id/url_bar",
        "com.android.chrome:id/omnibox_results_container",
        "com.android.chrome:id/line_1",
        "com.android.chrome:id/line_2"
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        createNotificationChannel()
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || !isProtectionActive) return

        val eventPackageName = event.packageName?.toString() ?: ""

        // 1. Update status aplikasi yang sedang aktif
        if (eventPackageName.isNotEmpty() && eventPackageName != currentActivePackage) {
            if (eventPackageName == "com.android.chrome") {
                chromeAppLaunchTime = System.currentTimeMillis()
            }
            currentActivePackage = eventPackageName
        }

        // 2. Hanya scan jika aplikasi adalah Browser (Hemat Baterai & Privasi)
        if (!browserPackages.contains(currentActivePackage)) return

        // 3. Cek Excluded Apps (Double check)
        if (excludedApps.contains(currentActivePackage)) return

        val currentTime = System.currentTimeMillis()
        if (currentTime - lastScanTime < SCAN_INTERVAL) return

        val rootNode = rootInActiveWindow ?: return
        
        try {
            // 4. Verifikasi ulang package name dari rootNode
            val actualPackage = rootNode.packageName?.toString() ?: ""
            if (!browserPackages.contains(actualPackage)) return

            // 5. Implementasi Safety Delay khusus Chrome
            if (actualPackage == "com.android.chrome") {
                if (currentTime - chromeAppLaunchTime < CHROME_SAFETY_DELAY) {
                    return 
                }
            }

            val sb = StringBuilder()
            extractTextRecursive(rootNode, sb)
            val capturedText = sb.toString()

            if (capturedText.isNotBlank()) {
                lastScanTime = currentTime
                
                // Kirim ke Flutter (AI Decision) - Tanpa blocking native langsung
                sendTextToFlutter(capturedText)

                // Blocking Native otomatis DIMATIKAN untuk mengurangi False Positive.
                // Biarkan AI di Flutter yang memutuskan kapan memanggil 'triggerNativeBlock'.
                /*
                if (checkText(capturedText)) {
                    triggerBlocking()
                }
                */
            }
        } finally {
            rootNode.recycle()
        }
    }

    private fun checkText(text: String): Boolean {
        return JUDI_REGEX.containsMatchIn(text) || combinedBlacklistRegex.containsMatchIn(text)
    }

    fun triggerBlocking(): Boolean {
        cancelPendingBlock()
        Handler(Looper.getMainLooper()).post {
            performGlobalAction(GLOBAL_ACTION_BACK)
            Handler(Looper.getMainLooper()).postDelayed({
                performGlobalAction(GLOBAL_ACTION_HOME)
            }, 300)
            incrementBlockedCount()
            showBlockingNotification()
            Toast.makeText(applicationContext, "GardaWara: ⛔ KONTEN JUDI DIBLOKIR!", Toast.LENGTH_LONG).show()
        }
        return true
    }

    private fun extractTextRecursive(node: AccessibilityNodeInfo?, sb: StringBuilder) {
        if (node == null) return

        val viewId = node.viewIdResourceName ?: ""
        if (ignoredViewIds.any { viewId.contains(it) }) return

        val rawText = node.text?.toString() ?: ""
        val contentDesc = node.contentDescription?.toString() ?: ""
        val combinedRaw = "$rawText $contentDesc".lowercase()

        val isSuggestion = combinedRaw.contains("suggested items") || 
                           combinedRaw.contains("refine:") || 
                           combinedRaw.contains("penelusuran populer")
        
        val isPlaceholder = placeholderTexts.any { combinedRaw.contains(it) }

        if (!isPlaceholder && !isSuggestion) {
            if (rawText.isNotBlank()) sb.append(rawText).append(" ")
            if (contentDesc.isNotBlank()) sb.append(contentDesc).append(" ")
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            extractTextRecursive(child, sb)
            child?.recycle()
        }
    }

    private fun cancelPendingBlock() {
        pendingBlockRunnable?.let { 
            debounceHandler.removeCallbacks(it)
            pendingBlockRunnable = null
        }
    }

    private fun incrementBlockedCount() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val currentCount = prefs.getLong("flutter.blocked_count", 0L)
        prefs.edit().putLong("flutter.blocked_count", currentCount + 1).apply()
    }

    private fun showBlockingNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, "GARDA_CHANNEL")
            .setContentTitle("🛡️ GardaWara Beraksi")
            .setContentText("Konten judi berhasil diblokir!")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        notificationManager.notify(1001, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "GARDA_CHANNEL", "GardaWara Protection", NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun sendTextToFlutter(text: String) {
        Handler(Looper.getMainLooper()).post {
            try {
                MainActivity.flutterEngineInstance?.dartExecutor?.binaryMessenger?.let { messenger ->
                    val channel = MethodChannel(messenger, "com.example.gardawara_ai/accessibility")
                    channel.invokeMethod("onTextDetected", text)
                }
            } catch (e: Exception) {
                Log.e("GardaService", "Gagal kirim ke Flutter: ${e.message}")
            }
        }
    }
}