# Android Persistent Background Service
**Status:** Production-ready template for achieving ~70–98% service persistence
**Target:** Any Android app requiring a persistent background service
**Applies To:** API 21+ (Android 5.0+), with specific notes for API 26+, 31+, 33+, 34+, 35+

---

## Table of Contents

- [Android Persistent Background Service](#android-persistent-background-service)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Compatibility Matrix](#compatibility-matrix)
  - [Tier 1: Core Requirements (Must Have)](#tier-1-core-requirements-must-have)
    - [1. Foreground Service with Notification](#1-foreground-service-with-notification)
    - [2. START\_STICKY Return Value](#2-start_sticky-return-value)
    - [3. Partial Wake Lock (CPU)](#3-partial-wake-lock-cpu)
    - [4. Battery Optimization Exemption](#4-battery-optimization-exemption)
    - [5. Notification Permission (Android 13+ / API 33+)](#5-notification-permission-android-13--api-33)
  - [Tier 2: Enhanced Persistence (Should Have)](#tier-2-enhanced-persistence-should-have)
    - [6. stopWithTask="false"](#6-stopwithtaskfalse)
    - [7. onTaskRemoved() Recovery Handler](#7-ontaskremoved-recovery-handler)
    - [8. BOOT\_COMPLETED Receiver](#8-boot_completed-receiver)
    - [9. Service Self-Initialization Pattern (Critical)](#9-service-self-initialization-pattern-critical)
    - [10. Watchdog / Health Check (Dual Strategy)](#10-watchdog--health-check-dual-strategy)
      - [Strategy A: WorkManager Watchdog (Preferred)](#strategy-a-workmanager-watchdog-preferred)
      - [Strategy B: AlarmManager Watchdog (Supplementary)](#strategy-b-alarmmanager-watchdog-supplementary)
    - [11. Wi-Fi Lock (Network Services Only)](#11-wi-fi-lock-network-services-only)
    - [12. Android 15+ dataSync Timeout Handling](#12-android-15-datasync-timeout-handling)
  - [Tier 3: OEM-Specific Handling (Critical for Production)](#tier-3-oem-specific-handling-critical-for-production)
    - [Problematic OEMs Reference Table](#problematic-oems-reference-table)
    - [OEM Guidance Implementation](#oem-guidance-implementation)
  - [Complete Manifest Template](#complete-manifest-template)
  - [Full Service Implementation](#full-service-implementation)
  - [Service Lifecycle \& Recovery Paths](#service-lifecycle--recovery-paths)
  - [Testing \& Debugging](#testing--debugging)
    - [ADB Commands for Testing Persistence](#adb-commands-for-testing-persistence)
    - [Automated Test Script](#automated-test-script)
  - [Logging \& Monitoring](#logging--monitoring)
    - [ServiceLogger Utility](#servicelogger-utility)
    - [Integration with Firebase Crashlytics (Optional)](#integration-with-firebase-crashlytics-optional)
  - [Google Play Store Compliance](#google-play-store-compliance)
    - [Foreground Service Type Justification](#foreground-service-type-justification)
    - [Policy Checklist](#policy-checklist)
    - [Declaration Form (Play Console)](#declaration-form-play-console)
  - [Troubleshooting Guide](#troubleshooting-guide)
    - [Common Issues and Solutions](#common-issues-and-solutions)
    - [API 31+ Background Start Restrictions](#api-31-background-start-restrictions)
  - [Quick Reference — Implementation Priority](#quick-reference--implementation-priority)
    - [MVP (Minimum Viable Persistence) — Day 1](#mvp-minimum-viable-persistence--day-1)
    - [Production Ready — Week 1](#production-ready--week-1)
    - [Bulletproof — Week 2+](#bulletproof--week-2)

---

## Overview

This checklist covers **all** techniques required to keep an Android background service alive and persistent. Applicable to:

- HTTP / WebSocket servers
- Background sync / upload services
- Media playback services
- Location tracking services
- MQTT / IoT clients
- Any long-running background task

---

## Compatibility Matrix

| Technique | API 21–25 | API 26–30 | API 31–32 | API 33 | API 34 | API 35+ |
|-----------|-----------|-----------|-----------|--------|--------|---------|
| Foreground Service | ✅ | ✅ Required | ✅ | ✅ | ✅ | ✅ |
| `FOREGROUND_SERVICE` permission | N/A | ✅ Required | ✅ | ✅ | ✅ | ✅ |
| Per-type FGS permissions | N/A | N/A | N/A | N/A | ✅ Required | ✅ Required |
| `POST_NOTIFICATIONS` permission | N/A | N/A | N/A | ✅ Required | ✅ | ✅ |
| Notification Channel | N/A | ✅ Required | ✅ | ✅ | ✅ | ✅ |
| Battery Optimization Exemption | N/A | ✅ | ✅ | ✅ | ✅ | ✅ |
| `SCHEDULE_EXACT_ALARM` | N/A | N/A | ✅ Required | ✅ | ✅ | ✅ |
| `dataSync` 6-hour timeout | N/A | N/A | N/A | N/A | N/A | ✅ Enforced |
| `WIFI_MODE_FULL_LOW_LATENCY` | N/A | N/A | N/A | N/A | ✅ Replaces HIGH_PERF | ✅ |

---

## Tier 1: Core Requirements (Must Have)

Without these, your service **will not survive** in the background.

---

### 1. Foreground Service with Notification

**What:** A service that shows a persistent notification, telling Android this is user-visible work.

**Why:** Required for Android 8+ (API 26). Without it, the system kills your service within ~1 minute of going to background.

**Manifest permissions:**

```xml
<!-- Base foreground service permission (API 26+) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Per-type permissions (API 34+ / Android 14+) — REQUIRED or app crashes -->
<!-- Include ONLY the types you actually use -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

**Manifest service declaration:**

```xml
<service
    android:name=".YourService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="specialUse"
    android:stopWithTask="false">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="Describe what your service does for Google Play review" />
</service>
```

**Foreground service types — choose the right one:**

| Type | Use Case | Extra Permission |
|------|----------|-----------------|
| `dataSync` | Sync/upload data | `FOREGROUND_SERVICE_DATA_SYNC` |
| `mediaPlayback` | Audio/video playback | `FOREGROUND_SERVICE_MEDIA_PLAYBACK` |
| `location` | GPS tracking | `FOREGROUND_SERVICE_LOCATION` + `ACCESS_FINE_LOCATION` |
| `specialUse` | Anything else (HTTP server, IoT, etc.) | `FOREGROUND_SERVICE_SPECIAL_USE` |
| `shortService` | Tasks < 3 min (API 34+) | None extra |

**Notification channel creation (required API 26+):**

```kotlin
private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Service Running",
            NotificationManager.IMPORTANCE_LOW // LOW = no sound, no peek
        ).apply {
            description = "Shows when the background service is active"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}
```

> ⚠️ Use `IMPORTANCE_LOW`, not `IMPORTANCE_MIN`. Some OEMs treat `MIN` as "not a real foreground service" and kill it.

**Build the notification:**

```kotlin
private fun buildNotification(): Notification {
    createNotificationChannel()

    val pendingIntent = PendingIntent.getActivity(
        this, 0,
        Intent(this, MainActivity::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    return NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Service Running")
        .setContentText("Your service is active")
        .setSmallIcon(R.drawable.ic_notification)
        .setContentIntent(pendingIntent)
        .setOngoing(true)
        .setSilent(true)
        .build()
}
```

**Start foreground (must call within 5 seconds):**

```kotlin
override fun onCreate() {
    super.onCreate()
    startForeground(NOTIFICATION_ID, buildNotification())
}
```

---

### 2. START_STICKY Return Value

**What:** Tells the system to recreate the service if it gets killed.

**Why:** Acts as a first line of defense against system kills. Note: this is a *hint*, not a guarantee — some OEMs ignore it.

```kotlin
override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    // intent may be null on restart if using START_STICKY
    // Your service logic here
    return START_STICKY
}
```

**Choosing the right return value:**

| Value | Behavior | Best For |
|-------|----------|----------|
| `START_STICKY` | Restart with `null` intent | Long-running services (servers, players) |
| `START_REDELIVER_INTENT` | Restart with original intent | One-shot tasks that need the original data |
| `START_NOT_STICKY` | Don't restart | Tasks that are safe to skip |

---

### 3. Partial Wake Lock (CPU)

**What:** Keeps the CPU running even when the screen is off.

**Why:** Without it, the CPU may sleep and your background processing stops — critical for network servers, media encoding, IoT communication.

**Manifest:**

```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**Implementation with safety timeout:**

```kotlin
private var wakeLock: PowerManager.WakeLock? = null

private fun acquireWakeLock() {
    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
    wakeLock = powerManager.newWakeLock(
        PowerManager.PARTIAL_WAKE_LOCK,
        "YourApp::YourServiceWakelock"
    )
    // IMPORTANT: Always use a timeout to prevent battery drain on crash
    wakeLock?.acquire(60 * 60 * 1000L) // 1 hour — re-acquire periodically
}

private fun releaseWakeLock() {
    try {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    } catch (e: Exception) {
        // Ignore — wake lock may already be released
    }
}
```

**Re-acquire periodically for long-running services:**

```kotlin
private val wakeLockRenewHandler = Handler(Looper.getMainLooper())
private val wakeLockRenewRunnable = object : Runnable {
    override fun run() {
        releaseWakeLock()
        acquireWakeLock()
        wakeLockRenewHandler.postDelayed(this, 50 * 60 * 1000L) // Renew every 50 min
    }
}
```

> ⚠️ **Never use `acquire()` without a timeout.** If your service crashes without calling `onDestroy()`, the wake lock leaks and drains the battery until reboot.

---

### 4. Battery Optimization Exemption

**What:** Requests the user to whitelist your app from Doze mode and App Standby.

**Why:** Doze mode defers alarms, network access, and jobs. Exemption lets your service run unrestricted.

**Manifest:**

```xml
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

**Implementation:**

```kotlin
private fun requestBatteryOptimizationExemption() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
            AlertDialog.Builder(this)
                .setTitle("Battery Optimization")
                .setMessage(
                    "To keep the service running reliably, please disable " +
                    "battery optimization for this app."
                )
                .setPositiveButton("Allow") { _, _ ->
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        ).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    } catch (e: Exception) {
                        // Fallback to general battery settings
                        startActivity(Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
                    }
                }
                .setNegativeButton("Later", null)
                .show()
        }
    }
}
```

> ⚠️ **Google Play Policy:** Using `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` is only allowed for apps whose core function requires it. See [Play Store Compliance](#google-play-store-compliance).

---

### 5. Notification Permission (Android 13+ / API 33+)

**What:** Runtime permission required to show notifications, including foreground service notifications.

**Why:** Without this permission on API 33+, your foreground service notification is invisible, and some OEMs may treat the service as not truly foreground.

**Manifest:**

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**Implementation:**

```kotlin
private fun requestNotificationPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            if (shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)) {
                AlertDialog.Builder(this)
                    .setTitle("Notification Permission Required")
                    .setMessage(
                        "This app needs notification permission to show the " +
                        "service status indicator."
                    )
                    .setPositiveButton("Grant") { _, _ ->
                        requestPermissionLauncher.launch(
                            Manifest.permission.POST_NOTIFICATIONS
                        )
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            } else {
                requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }
}

private val requestPermissionLauncher = registerForActivityResult(
    ActivityResultContracts.RequestPermission()
) { isGranted ->
    if (isGranted) {
        // Permission granted — start or restart service
        startYourService()
    } else {
        // Explain that the service may not work properly
        showPermissionDeniedExplanation()
    }
}
```

---

## Tier 2: Enhanced Persistence (Should Have)

These significantly improve reliability, especially against user actions and system events.

---

### 6. stopWithTask="false"

**What:** Prevents the service from being killed when the user swipes the app from the recents screen.

**Why:** By default, swiping an app from recents kills its services. This flag overrides that behavior.

```xml
<service
    android:name=".YourService"
    android:stopWithTask="false"
    ... />
```

> ⚠️ Some OEMs (Xiaomi, Huawei) ignore this flag. Combine with `onTaskRemoved()` for best results.

---

### 7. onTaskRemoved() Recovery Handler

**What:** Called when the user removes the app from the recents screen. Schedules a service restart.

**Why:** Even with `stopWithTask="false"`, some OEMs still kill the service. This is a safety net.

```kotlin
override fun onTaskRemoved(rootIntent: Intent?) {
    super.onTaskRemoved(rootIntent)
    logEvent("onTaskRemoved called — scheduling restart")

    val restartIntent = Intent(this, ServiceRestartReceiver::class.java).apply {
        action = "com.yourapp.RESTART_SERVICE"
    }
    val pendingIntent = PendingIntent.getBroadcast(
        this, 1, restartIntent,
        PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
    )
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarmManager.set(
        AlarmManager.ELAPSED_REALTIME_WAKEUP,
        SystemClock.elapsedRealtime() + 1000,
        pendingIntent
    )
}
```

**ServiceRestartReceiver:**

```kotlin
class ServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        logEvent("ServiceRestartReceiver triggered")
        val serviceIntent = Intent(context, YourService::class.java)
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (e: Exception) {
            logEvent("Failed to restart service: ${e.message}")
        }
    }
}
```

---

### 8. BOOT_COMPLETED Receiver

**What:** Auto-starts the service after device reboot.

**Why:** Reboots kill all services. Without this, the user must manually open the app after every reboot.

**Manifest:**

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<receiver
    android:name=".BootReceiver"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <!-- Huawei-specific -->
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

**Implementation:**

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val validActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON"
        )
        if (intent?.action in validActions) {
            val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
            if (prefs.getBoolean("service_enabled", false)) {
                logEvent("Boot completed — starting service")
                val serviceIntent = Intent(context, YourService::class.java)
                try {
                    ContextCompat.startForegroundService(context, serviceIntent)
                } catch (e: Exception) {
                    logEvent("Failed to start service on boot: ${e.message}")
                }
            }
        }
    }
}
```

> ⚠️ **Android 15+:** `BOOT_COMPLETED` may not be delivered to apps the user has never opened. Ensure your app has been launched at least once.

---

### 9. Service Self-Initialization Pattern (Critical)

**What:** The service initializes its core resources (HTTP server, database, TTS engine, etc.) in `onCreate()`, without waiting for the Activity to provide them.

**Why:** A common architectural mistake is designing the Service as a "dumb host" that requires the Activity to initialize resources. After a device reboot, the Service starts via `BOOT_COMPLETED`, but the Activity is never opened. The Service shows a notification (appearing "Running") but doesn't actually work because its resources were never initialized.

**The Anti-Pattern (What NOT to do):**

```kotlin
// ❌ BROKEN: Service waits for Activity to provide resources
class BrokenService : Service() {
    private lateinit var server: HttpServer
    
    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildNotification())
        // Server NOT started here - waiting for Activity!
    }
    
    // Called by MainActivity after bind
    fun initServer(config: ServerConfig) {
        server = HttpServer(config)  // Never called on boot!
        server.start()
    }
}
```

**Result after reboot:** Notification shows "Running", but server isn't listening. Connection refused.

---

**The Correct Pattern (What TO do):**

```kotlin
// ✅ CORRECT: Service self-initializes, Activity can connect later
class AutonomousService : Service() {
    private lateinit var server: HttpServer
    
    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildNotification())
        initializeServer()  // Start immediately, don't wait!
    }
    
    private fun initializeServer() {
        val config = loadServerConfig()  // From SharedPreferences, assets, etc.
        server = HttpServer(config)
        server.start()
        Log.i(TAG, "Server started on port ${config.port}")
    }
    
    // Optional: Activity can bind and get updates
    fun getServerStatus(): ServerStatus {
        return ServerStatus(server.isRunning, server.port)
    }
}
```

**Result after reboot:** Server is actually listening and functional immediately.

---

**Shared Initializer Pattern (For Complex Initialization):**

When initialization logic is complex (loading ML models, copying assets, etc.), extract it to a reusable initializer that both Service and Activity can use:

```kotlin
// Singleton initializer - no UI dependencies
object ResourceInitializer {
    fun initialize(context: Context): ServiceResources? {
        return try {
            // Copy assets, load models, create configs
            val resources = ServiceResources(/* ... */)
            resources.prepare()
            resources
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            null
        }
    }
}

// Service calls it in onCreate()
class AutonomousService : Service() {
    private var resources: ServiceResources? = null
    
    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildNotification())
        
        // Initialize in background coroutine
        CoroutineScope(Dispatchers.IO).launch {
            resources = ResourceInitializer.initialize(applicationContext)
            if (resources != null) {
                startServer()
            } else {
                showErrorNotification("Failed to initialize service")
            }
        }
    }
}

// Activity can also use the same initializer
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Activity can share the Service's instance or initialize its own
        bindToService()  // Gets reference to already-initialized service
    }
}
```

---

**Widget State Synchronization:**

Widgets must validate actual service state, not just read from SharedPreferences:

```kotlin
class ServiceWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        // Don't trust SharedPreferences after reboot!
        val isServiceActuallyRunning = isServiceRunning(context)
        
        val prefs = context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val isServerRunning = if (isServiceActuallyRunning) {
            prefs.getBoolean(PREF_SERVER_RUNNING, false)
        } else {
            false  // Force false when service not running
        }
        
        // Update widget UI...
    }
    
    private fun isServiceRunning(context: Context): Boolean {
        val manager = context.getSystemService(ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        return manager.getRunningServices(Integer.MAX_VALUE)
            .any { it.service.className == AutonomousService::class.java.name }
    }
}
```

---

**Key Principles:**

| Principle | Rationale |
|-----------|-----------|
| **Service must be autonomous** | Background services run independently of UI lifecycle |
| **Initialize in `onCreate()`** | Don't wait for external triggers that may never come |
| **Use background coroutines** | Heavy initialization (ML models, asset copying) must not block main thread |
| **Share initialization logic** | Extract to singleton to avoid code duplication between Service and Activity |
| **Validate actual state** | Widgets and UIs should check if service is actually running, not trust cached state |

> 📚 **HTTP Server Specifics:** For Javalin/Jetty HTTP server boot-time initialization (port binding, SO_REUSEADDR, retry logic), see [how-to-code-android-persistent-javalin-server.md](how-to-code-android-persistent-javalin-server.md) Section "Boot-Time Self-Initialization".

---

### 10. Watchdog / Health Check (Dual Strategy)

**What:** Periodic checks that restart the service if it has silently died.

**Why:** `START_STICKY` is a hint, not a guarantee. Services can die silently without `onDestroy()` being called.

#### Strategy A: WorkManager Watchdog (Preferred)

WorkManager survives Doze mode better than AlarmManager and is battery-friendly.

```kotlin
class ServiceWatchdogWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        if (!YourService.isRunning) {
            logEvent("Watchdog: Service not running — restarting")
            val intent = Intent(applicationContext, YourService::class.java)
            try {
                ContextCompat.startForegroundService(applicationContext, intent)
            } catch (e: Exception) {
                logEvent("Watchdog: Failed to restart: ${e.message}")
            }
        }
        return Result.success()
    }
}
```

**Schedule the watchdog:**

```kotlin
fun scheduleWatchdog(context: Context) {
    val watchdogWork = PeriodicWorkRequestBuilder<ServiceWatchdogWorker>(
        15, TimeUnit.MINUTES // Minimum interval for periodic work
    ).setBackoffCriteria(
        BackoffPolicy.LINEAR,
        1, TimeUnit.MINUTES
    ).build()

    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
        "service_watchdog",
        ExistingPeriodicWorkPolicy.KEEP,
        watchdogWork
    )
}
```

#### Strategy B: AlarmManager Watchdog (Supplementary)

```kotlin
private fun scheduleAlarmWatchdog() {
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val intent = Intent(this, WatchdogReceiver::class.java)
    val pendingIntent = PendingIntent.getBroadcast(
        this, 0, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    alarmManager.setInexactRepeating(
        AlarmManager.ELAPSED_REALTIME_WAKEUP,
        SystemClock.elapsedRealtime() + 5 * 60 * 1000,
        5 * 60 * 1000,
        pendingIntent
    )
}
```

**Service running detection (replaces deprecated `getRunningServices`):**

```kotlin
// In YourService — use a static volatile flag
companion object {
    @Volatile
    var isRunning: Boolean = false
        private set

    const val NOTIFICATION_ID = 1
    const val CHANNEL_ID = "your_service_channel"
}

override fun onCreate() {
    super.onCreate()
    isRunning = true
    // ... rest of onCreate
}

override fun onDestroy() {
    isRunning = false
    // ... rest of onDestroy
    super.onDestroy()
}
```

> ⚠️ **Do NOT use `ActivityManager.getRunningServices()`** — it is deprecated since API 26 and unreliable on many OEMs.

---

### 11. Wi-Fi Lock (Network Services Only)

**What:** Prevents the Wi-Fi radio from entering power-saving mode.

**Why:** In power-saving mode, Wi-Fi may become unreachable from other devices on the LAN.

**When to use:**
- ✅ HTTP/WebSocket servers accessible over LAN
- ✅ IoT clients requiring constant Wi-Fi connectivity
- ❌ Localhost-only services (127.0.0.1)
- ❌ Services using mobile data only

**Manifest:**

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

**Implementation (handles deprecation):**

```kotlin
private var wifiLock: WifiManager.WifiLock? = null

private fun acquireWifiLock() {
    val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    wifiLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        wifiManager.createWifiLock(
            WifiManager.WIFI_MODE_FULL_LOW_LATENCY,
            "YourApp::WifiLock"
        )
    } else {
        @Suppress("DEPRECATION")
        wifiManager.createWifiLock(
            WifiManager.WIFI_MODE_FULL_HIGH_PERF,
            "YourApp::WifiLock"
        )
    }
    wifiLock?.acquire()
}

private fun releaseWifiLock() {
    try {
        if (wifiLock?.isHeld == true) {
            wifiLock?.release()
        }
    } catch (e: Exception) {
        // Ignore
    }
}
```

---

### 12. Android 15+ dataSync Timeout Handling

**What:** Android 15 (API 35) enforces a **6-hour time limit** on `dataSync` foreground services.

**Why:** After 6 hours, the system calls `onTimeout()`. You must stop within seconds or get an ANR.

```kotlin
// Only needed if using foregroundServiceType="dataSync"
override fun onTimeout(startId: Int, fgsType: Int) {
    logEvent("dataSync timeout reached — stopping and rescheduling")

    // Option 1: Stop and let watchdog restart
    stopSelf()

    // Option 2: Transition to a different FGS type
    // (requires stopping and restarting with new type)
}
```

**Alternatives for API 35+:**
- Use `specialUse` type instead (no timeout, but needs Play Store justification)
- Use `shortService` for tasks < 3 minutes
- Stop and restart the service to reset the timer

---

## Tier 3: OEM-Specific Handling (Critical for Production)

**75% of Android devices** have aggressive OEM-specific battery optimizations that **ignore standard Android APIs**.

---

### Problematic OEMs Reference Table

| OEM | Kill Aggressiveness | Issue | User Action Required |
|-----|:-------------------:|-------|---------------------|
| **Xiaomi (MIUI/HyperOS)** | 🔴 Very High | AutoStart disabled by default, aggressive RAM management | Enable Auto-start + Lock app in recents |
| **Samsung (One UI)** | 🟠 High | "Sleeping apps" and "Deep sleeping apps" lists | Add to "Never sleeping apps" |
| **Huawei (EMUI/HarmonyOS)** | 🔴 Very High | App Launch Manager kills by default | Set to "Manage manually" (all toggles ON) |
| **OnePlus (OxygenOS)** | 🟠 High | Deep Optimization enabled by default | Disable battery optimization |
| **Oppo (ColorOS)** | 🔴 Very High | Aggressive RAM and background management | Enable Auto-start + disable battery optimization |
| **Vivo (Funtouch/OriginOS)** | 🔴 Very High | Background power consumption management | Enable Autostart + high background power consumption |
| **Realme (Realme UI)** | 🔴 Very High | Same as Oppo (ColorOS-based) | Same as Oppo |
| **Asus (ZenUI)** | 🟡 Medium | Auto-start manager | Enable Auto-start |
| **Nokia (stock-ish)** | 🟡 Medium | DuraSpeed / Evenwell | Disable DuraSpeed in settings |
| **Google Pixel** | 🟢 Low | Standard Android behavior | Battery optimization exemption is sufficient |

> 📖 **Canonical reference:** [dontkillmyapp.com](https://dontkillmyapp.com)

---

### OEM Guidance Implementation

```kotlin
object OemGuidance {

    data class OemInfo(
        val name: String,
        val message: String,
        val intentActions: List<String> = emptyList()
    )

    fun getOemInfo(): OemInfo? {
        val manufacturer = Build.MANUFACTURER.lowercase()
        return when {
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") ||
            manufacturer.contains("poco") -> OemInfo(
                name = "Xiaomi/Redmi/POCO",
                message = """
                    For reliable background operation on ${Build.MANUFACTURER}:

                    1. Go to Settings → Apps → Your App → Auto-start → Enable
                    2. Go to Settings → Apps → Your App → Battery saver → No restrictions
                    3. Lock the app in Recent Apps (swipe down on the app card)
                    4. Settings → Battery → Ultra battery saver → Disable
                """.trimIndent(),
                intentActions = listOf(
                    "miui.intent.action.APP_PERM_EDITOR",
                    "miui.intent.action.POWER_HIDE_MODE_APP_LIST"
                )
            )

            manufacturer.contains("samsung") -> OemInfo(
                name = "Samsung",
                message = """
                    For reliable background operation on Samsung:

                    1. Settings → Apps → Your App → Battery → Unrestricted
                    2. Settings → Battery → Background usage limits → Never sleeping apps → Add your app
                    3. Settings → Device care → Battery → Background usage limits → Never sleeping apps
                """.trimIndent()
            )

            manufacturer.contains("huawei") || manufacturer.contains("honor") -> OemInfo(
                name = "Huawei/Honor",
                message = """
                    For reliable background operation on ${Build.MANUFACTURER}:

                    1. Settings → Apps → App launch → Your App → Manage manually
                       Enable ALL three toggles: Auto-launch, Secondary launch, Run in background
                    2. Settings → Battery → App launch → Your App → Manage manually
                    3. Lock the app in Recent Apps
                """.trimIndent(),
                intentActions = listOf(
                    "huawei.intent.action.HSM_BOOTAPP_MANAGER"
                )
            )

            manufacturer.contains("oneplus") -> OemInfo(
                name = "OnePlus",
                message = """
                    For reliable background operation on OnePlus:

                    1. Settings → Apps → Your App → Battery → Don't optimize
                    2. Settings → Battery → Battery optimization → Your App → Don't optimize
                    3. Lock the app in Recent Apps
                """.trimIndent()
            )

            manufacturer.contains("oppo") || manufacturer.contains("realme") -> OemInfo(
                name = "Oppo/Realme",
                message = """
                    For reliable background operation on ${Build.MANUFACTURER}:

                    1. Settings → App Management → Your App → Auto-start → Enable
                    2. Settings → Battery → More settings → Optimize battery use → Your App → Don't optimize
                    3. Lock the app in Recent Apps
                """.trimIndent()
            )

            manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> OemInfo(
                name = "Vivo/iQOO",
                message = """
                    For reliable background operation on ${Build.MANUFACTURER}:

                    1. Settings → Apps → Your App → Autostart → Enable
                    2. Settings → Battery → Background power consumption management → Your App → Allow
                    3. Lock the app in Recent Apps
                """.trimIndent()
            )

            manufacturer.contains("asus") -> OemInfo(
                name = "Asus",
                message = """
                    For reliable background operation on Asus:

                    1. Settings → Apps → Auto-start Manager → Your App → Allow
                    2. Settings → Battery → PowerMaster → Your App → Don't restrict
                """.trimIndent()
            )

            manufacturer.contains("nokia") -> OemInfo(
                name = "Nokia",
                message = """
                    For reliable background operation on Nokia:

                    1. Settings → Apps → Your App → Battery → Don't optimize
                    2. Settings → Battery → Background activity → Your App → Enable
                    3. If available: Settings → System → Developer options → DuraSpeed → Disable
                """.trimIndent()
            )

            else -> null // Stock Android or unknown — standard APIs should work
        }
    }

    fun showGuidanceDialog(context: Context) {
        val oemInfo = getOemInfo() ?: return

        AlertDialog.Builder(context)
            .setTitle("${oemInfo.name} — Settings Required")
            .setMessage(oemInfo.message)
            .setPositiveButton("Open Settings") { _, _ ->
                // Try OEM-specific intent first
                for (action in oemInfo.intentActions) {
                    try {
                        context.startActivity(Intent(action).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        return@setPositiveButton
                    } catch (_: Exception) { }
                }
                // Fallback to general settings
                try {
                    context.startActivity(Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
                } catch (_: Exception) {
                    context.startActivity(Intent(Settings.ACTION_SETTINGS))
                }
            }
            .setNeutralButton("Learn More") { _, _ ->
                context.startActivity(Intent(Intent.ACTION_VIEW,
                    Uri.parse("https://dontkillmyapp.com")))
            }
            .setNegativeButton("Later", null)
            .show()
    }

    /**
     * Check if OEM guidance should be shown.
     * Call this from MainActivity.onCreate() or a setup wizard.
     */
    fun shouldShowGuidance(context: Context): Boolean {
        val prefs = context.getSharedPreferences("oem_guidance", Context.MODE_PRIVATE)
        if (prefs.getBoolean("dismissed", false)) return false
        return getOemInfo() != null
    }

    fun markDismissed(context: Context) {
        context.getSharedPreferences("oem_guidance", Context.MODE_PRIVATE)
            .edit().putBoolean("dismissed", true).apply()
    }
}
```

---

## Complete Manifest Template

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- ═══════════════════════════════════════════ -->
    <!-- Core Permissions                            -->
    <!-- ═══════════════════════════════════════════ -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Per-type FGS permissions (API 34+ / Android 14+) -->
    <!-- Include ONLY the types you use -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <!-- <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" /> -->
    <!-- <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" /> -->
    <!-- <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" /> -->

    <!-- ═══════════════════════════════════════════ -->
    <!-- Persistence Permissions                     -->
    <!-- ═══════════════════════════════════════════ -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <!-- ═══════════════════════════════════════════ -->
    <!-- Network Permissions (if needed)             -->
    <!-- ═══════════════════════════════════════════ -->
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- ═══════════════════════════════════════════ -->
    <!-- Alarm Permissions (API 31+)                 -->
    <!-- ═══════════════════════════════════════════ -->
    <!-- Only if using exact alarms for watchdog -->
    <!-- <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        android:maxSdkVersion="32" /> -->
    <!-- <uses-permission android:name="android.permission.USE_EXACT_ALARM" /> -->

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.YourApp">

        <!-- ═══════════════════════════════════════ -->
        <!-- Activities                              -->
        <!-- ═══════════════════════════════════════ -->
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- ═══════════════════════════════════════ -->
        <!-- Foreground Service                      -->
        <!-- ═══════════════════════════════════════ -->
        <service
            android:name=".YourService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="specialUse"
            android:stopWithTask="false">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Runs a local HTTP server for LAN device communication" />
        </service>

        <!-- ═══════════════════════════════════════ -->
        <!-- Boot Receiver                           -->
        <!-- ═══════════════════════════════════════ -->
        <receiver
            android:name=".BootReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>

        <!-- ═══════════════════════════════════════ -->
        <!-- Service Restart Receiver                -->
        <!-- ═══════════════════════════════════════ -->
        <receiver
            android:name=".ServiceRestartReceiver"
            android:exported="false" />

        <!-- ═══════════════════════════════════════ -->
        <!-- Watchdog Receiver (AlarmManager-based)  -->
        <!-- ═══════════════════════════════════════ -->
        <receiver
            android:name=".WatchdogReceiver"
            android:exported="false" />

    </application>
</manifest>
```

---

## Full Service Implementation

Complete, production-ready service combining all techniques:

```kotlin
class YourService : Service() {

    companion object {
        @Volatile
        var isRunning: Boolean = false
            private set

        const val NOTIFICATION_ID = 1
        const val CHANNEL_ID = "your_service_channel"
        private const val TAG = "YourService"
        private const val WAKELOCK_TIMEOUT = 60 * 60 * 1000L // 1 hour
        private const val WAKELOCK_RENEW_INTERVAL = 50 * 60 * 1000L // 50 minutes
        private const val WATCHDOG_INTERVAL = 5 * 60 * 1000L // 5 minutes
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // ═══════════════════════════════════════════════════
    // Lifecycle
    // ═══════════════════════════════════════════════════

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        logEvent("Service onCreate")

        startForeground(NOTIFICATION_ID, buildNotification())
        acquireWakeLock()
        acquireWifiLock()    // Remove if not a network service
        scheduleAlarmWatchdog()
        scheduleWakeLockRenewal()

        // ── Start your actual work here ──
        startYourWork()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        logEvent("onStartCommand — intent=${intent?.action}, flags=$flags")

        // Handle null intent (restart after kill)
        if (intent == null) {
            logEvent("Service restarted by system (null intent)")
        }

        return START_STICKY
    }

    override fun onDestroy() {
        logEvent("Service onDestroy")
        isRunning = false

        // ── Stop your actual work here ──
        stopYourWork()

        handler.removeCallbacksAndMessages(null)
        serviceScope.cancel()
        releaseWakeLock()
        releaseWifiLock()
        cancelAlarmWatchdog()

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        logEvent("onTaskRemoved — scheduling restart")

        val restartIntent = Intent(this, ServiceRestartReceiver::class.java).apply {
            action = "com.yourapp.RESTART_SERVICE"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, 1, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 1000,
            pendingIntent
        )
    }

    // Android 15+ dataSync timeout (only if using dataSync type)
    // override fun onTimeout(startId: Int, fgsType: Int) {
    //     logEvent("FGS timeout reached — stopping")
    //     stopSelf()
    // }

    // ═══════════════════════════════════════════════════
    // Notification
    // ═══════════════════════════════════════════════════

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Service Running",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when the background service is active"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        createNotificationChannel()

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Service Running")
            .setContentText("Your service is active")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    fun updateNotification(text: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Service Running")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setSilent(true)
            .build()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    // ═══════════════════════════════════════════════════
    // Wake Lock
    // ═══════════════════════════════════════════════════

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "YourApp::ServiceWakeLock"
        )
        wakeLock?.acquire(WAKELOCK_TIMEOUT)
        logEvent("WakeLock acquired (timeout=${WAKELOCK_TIMEOUT}ms)")
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                logEvent("WakeLock released")
            }
        } catch (e: Exception) {
            logEvent("WakeLock release error: ${e.message}")
        }
    }

    private val wakeLockRenewRunnable = object : Runnable {
        override fun run() {
            releaseWakeLock()
            acquireWakeLock()
            logEvent("WakeLock renewed")
            handler.postDelayed(this, WAKELOCK_RENEW_INTERVAL)
        }
    }

    private fun scheduleWakeLockRenewal() {
        handler.postDelayed(wakeLockRenewRunnable, WAKELOCK_RENEW_INTERVAL)
    }

    // ═══════════════════════════════════════════════════
    // Wi-Fi Lock (remove if not a network service)
    // ═══════════════════════════════════════════════════

    private fun acquireWifiLock() {
        val wifiManager = applicationContext
            .getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            wifiManager.createWifiLock(
                WifiManager.WIFI_MODE_FULL_LOW_LATENCY,
                "YourApp::WifiLock"
            )
        } else {
            @Suppress("DEPRECATION")
            wifiManager.createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                "YourApp::WifiLock"
            )
        }
        wifiLock?.acquire()
        logEvent("WifiLock acquired")
    }

    private fun releaseWifiLock() {
        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
                logEvent("WifiLock released")
            }
        } catch (e: Exception) {
            logEvent("WifiLock release error: ${e.message}")
        }
    }

    // ═══════════════════════════════════════════════════
    // Alarm Watchdog
    // ═══════════════════════════════════════════════════

    private fun scheduleAlarmWatchdog() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WatchdogReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + WATCHDOG_INTERVAL,
            WATCHDOG_INTERVAL,
            pendingIntent
        )
        logEvent("Alarm watchdog scheduled (interval=${WATCHDOG_INTERVAL}ms)")
    }

    private fun cancelAlarmWatchdog() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WatchdogReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    // ═══════════════════════════════════════════════════
    // Your actual work goes here
    // ═══════════════════════════════════════════════════

    private fun startYourWork() {
        serviceScope.launch {
            // Example: start HTTP server, MQTT client, etc.
            logEvent("Work started")
        }
    }

    private fun stopYourWork() {
        // Example: stop HTTP server, MQTT client, etc.
        logEvent("Work stopped")
    }

    // ═══════════════════════════════════════════════════
    // Logging
    // ═══════════════════════════════════════════════════

    private fun logEvent(event: String) {
        Log.d(TAG, event)
        ServiceLogger.log(this, TAG, event)
    }
}
```

---

## Service Lifecycle & Recovery Paths

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LIFECYCLE DIAGRAM                     │
└─────────────────────────────────────────────────────────────────┘

┌──────────┐     ┌──────────────┐     ┌────────────────┐
│ App      │────▶│ startForeground│────▶│   RUNNING      │
│ Launch   │     │ Service()     │     │   (Foreground)  │
└──────────┘     └──────────────┘     └───────┬────────┘
                                              │
                        ┌─────────────────────┼─────────────────────┐
                        │                     │                     │
                        ▼                     ▼                     ▼
                 ┌──────────────┐    ┌───────────────┐    ┌──────────────┐
                 │ System Kill  │    │ User Swipe    │    │ Device       │
                 │ (OOM/Doze)   │    │ from Recents  │    │ Reboot       │
                 └──────┬───────┘    └──────┬────────┘    └──────┬───────┘
                        │                   │                     │
                        ▼                   ▼                     ▼
                 ┌──────────────┐    ┌───────────────┐    ┌──────────────┐
                 │ START_STICKY │    │ onTaskRemoved │    │ BOOT_        │
                 │ (system      │    │ → AlarmManager│    │ COMPLETED    │
                 │  restart)    │    │   restart     │    │ receiver     │
                 └──────┬───────┘    └──────┬────────┘    └──────┬───────┘
                        │                   │                     │
                        │     ┌─────────────┘                     │
                        │     │                                   │
                        ▼     ▼                                   ▼
                 ┌──────────────────────────────────────────────────┐
                 │              SERVICE RESTARTED                    │
                 └──────────────────────────────────────────────────┘
                                      ▲
                                      │
                        ┌─────────────┴──────────────┐
                        │                            │
                 ┌──────────────┐          ┌──────────────┐
                 │ WorkManager  │          │ AlarmManager │
                 │ Watchdog     │          │ Watchdog     │
                 │ (every 15m)  │          │ (every 5m)   │
                 └──────────────┘          └──────────────┘
                        │                            │
                        └─────────────┬──────────────┘
                                      │
                                      ▼
                               ┌──────────────┐
                               │ Silent Death  │
                               │ (no callback) │
                               └──────────────┘
```

---

## Testing & Debugging

### ADB Commands for Testing Persistence

```bash
# ═══════════════════════════════════════════════════════
# SERVICE STATUS
# ═══════════════════════════════════════════════════════

# Check if service is running
adb shell dumpsys activity services <package>/<service-class>

# List all running services for your package
adb shell dumpsys activity services | grep <package>

# Check foreground service status
adb shell dumpsys activity services | grep "isForeground"

# ═══════════════════════════════════════════════════════
# SIMULATE SYSTEM KILLS
# ═══════════════════════════════════════════════════════

# Force-stop (simulates OEM aggressive kill)
adb shell am force-stop <package>

# Kill process (simulates OOM kill — START_STICKY should recover)
adb shell am kill <package>

# Kill background processes
adb shell am kill-all

# ═══════════════════════════════════════════════════════
# SIMULATE DOZE MODE
# ═══════════════════════════════════════════════════════

# Enable Doze mode
adb shell dumpsys deviceidle enable

# Force device into Doze
adb shell dumpsys deviceidle force-idle

# Check Doze state
adb shell dumpsys deviceidle

# Exit Doze
adb shell dumpsys deviceidle unforce

# Disable Doze
adb shell dumpsys deviceidle disable

# ═══════════════════════════════════════════════════════
# SIMULATE APP STANDBY
# ═══════════════════════════════════════════════════════

# Set app to standby
adb shell am set-inactive <package> true

# Check standby status
adb shell am get-inactive <package>

# Remove from standby
adb shell am set-inactive <package> false

# ═══════════════════════════════════════════════════════
# BATTERY OPTIMIZATION
# ═══════════════════════════════════════════════════════

# Check if app is whitelisted from battery optimization
adb shell dumpsys deviceidle whitelist

# Add to whitelist (for testing)
adb shell dumpsys deviceidle whitelist +<package>

# Remove from whitelist
adb shell dumpsys deviceidle whitelist -<package>

# ═══════════════════════════════════════════════════════
# SIMULATE BOOT
# ═══════════════════════════════════════════════════════

# Send BOOT_COMPLETED broadcast
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p <package>

# ═══════════════════════════════════════════════════════
# WAKE LOCKS
# ═══════════════════════════════════════════════════════

# Check active wake locks
adb shell dumpsys power | grep -i "wake lock"

# Detailed power info
adb shell dumpsys power

# ═══════════════════════════════════════════════════════
# ALARMS
# ═══════════════════════════════════════════════════════

# Check scheduled alarms for your package
adb shell dumpsys alarm | grep <package>

# ═══════════════════════════════════════════════════════
# WORKMANAGER
# ═══════════════════════════════════════════════════════

# Check WorkManager status
adb shell dumpsys jobscheduler | grep <package>
```

### Automated Test Script

```bash
#!/bin/bash
# save as test_persistence.sh
PACKAGE="com.yourapp"
SERVICE="com.yourapp.YourService"

echo "=== Android Service Persistence Test ==="
echo ""

echo "1. Checking service status..."
adb shell dumpsys activity services $PACKAGE | grep -c "ServiceRecord" && \
    echo "   ✅ Service is running" || echo "   ❌ Service is NOT running"
echo ""

echo "2. Testing OOM kill recovery (am kill)..."
adb shell am kill $PACKAGE
sleep 5
adb shell dumpsys activity services $PACKAGE | grep -c "ServiceRecord" && \
    echo "   ✅ Service recovered from OOM kill" || echo "   ❌ Service did NOT recover"
echo ""

echo "3. Testing force-stop recovery..."
adb shell am force-stop $PACKAGE
echo "   Waiting 10 seconds for watchdog..."
sleep 10
adb shell dumpsys activity services $PACKAGE | grep -c "ServiceRecord" && \
    echo "   ✅ Service recovered from force-stop" || \
    echo "   ⚠️  Service did NOT recover (expected — force-stop kills everything)"
echo ""

echo "4. Testing Doze mode..."
adb shell am start -n $PACKAGE/.MainActivity
sleep 2
adb shell input keyevent KEYCODE_HOME
sleep 1
adb shell dumpsys deviceidle enable
adb shell dumpsys deviceidle force-idle
sleep 10
adb shell dumpsys activity services $PACKAGE | grep -c "ServiceRecord" && \
    echo "   ✅ Service survived Doze" || echo "   ❌ Service killed by Doze"
adb shell dumpsys deviceidle unforce
adb shell dumpsys deviceidle disable
echo ""

echo "5. Checking wake lock..."
adb shell dumpsys power | grep "YourApp" && \
    echo "   ✅ Wake lock is held" || echo "   ❌ No wake lock found"
echo ""

echo "=== Test Complete ==="
```

---

## Logging & Monitoring

### ServiceLogger Utility

```kotlin
object ServiceLogger {
    private const val MAX_LOG_ENTRIES = 500
    private const val PREFS_NAME = "service_log"
    private const val KEY_LOG = "log_entries"
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

    fun log(context: Context, tag: String, message: String) {
        val timestamp = dateFormat.format(Date())
        val entry = "$timestamp [$tag] $message"

        Log.d(tag, message) // Also log to Logcat

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_LOG, "") ?: ""
        val lines = existing.lines().takeLast(MAX_LOG_ENTRIES - 1)
        val updated = (lines + entry).joinToString("\n")
        prefs.edit().putString(KEY_LOG, updated).apply()
    }

    fun getLog(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_LOG, "No log entries") ?: "No log entries"
    }

    fun clearLog(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().remove(KEY_LOG).apply()
    }

    /**
     * Export log to a file for sharing/debugging
     */
    fun exportLog(context: Context): File {
        val log = getLog(context)
        val file = File(context.cacheDir, "service_log_${System.currentTimeMillis()}.txt")
        file.writeText(log)
        return file
    }

    /**
     * Log service uptime statistics
     */
    fun logUptimeStats(context: Context) {
        val prefs = context.getSharedPreferences("service_stats", Context.MODE_PRIVATE)
        val startCount = prefs.getInt("start_count", 0)
        val lastStart = prefs.getLong("last_start", 0)
        val totalUptime = prefs.getLong("total_uptime", 0)

        log(context, "Stats",
            "Starts: $startCount, " +
            "Total uptime: ${totalUptime / 1000 / 60}min, " +
            "Last start: ${if (lastStart > 0) dateFormat.format(Date(lastStart)) else "never"}"
        )
    }

    fun recordServiceStart(context: Context) {
        val prefs = context.getSharedPreferences("service_stats", Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("start_count", prefs.getInt("start_count", 0) + 1)
            .putLong("last_start", System.currentTimeMillis())
            .apply()
    }

    fun recordServiceStop(context: Context) {
        val prefs = context.getSharedPreferences("service_stats", Context.MODE_PRIVATE)
        val lastStart = prefs.getLong("last_start", 0)
        if (lastStart > 0) {
            val sessionUptime = System.currentTimeMillis() - lastStart
            val totalUptime = prefs.getLong("total_uptime", 0) + sessionUptime
            prefs.edit().putLong("total_uptime", totalUptime).apply()
        }
    }
}
```

### Integration with Firebase Crashlytics (Optional)

```kotlin
// Add to ServiceLogger.log() for production monitoring
fun logWithCrashlytics(tag: String, message: String) {
    Firebase.crashlytics.log("[$tag] $message")
}

// Track service lifecycle events as custom keys
fun trackServiceState(state: String) {
    Firebase.crashlytics.setCustomKey("service_state", state)
    Firebase.crashlytics.setCustomKey("service_last_event", System.currentTimeMillis())
}

// Report non-fatal exceptions for service issues
fun reportServiceIssue(tag: String, message: String, exception: Exception? = null) {
    Firebase.crashlytics.log("[$tag] $message")
    if (exception != null) {
        Firebase.crashlytics.recordException(exception)
    } else {
        Firebase.crashlytics.recordException(
            RuntimeException("Service issue: $message")
        )
    }
}
```

**Usage in your service:**

```kotlin
override fun onCreate() {
    super.onCreate()
    ServiceLogger.recordServiceStart(this)
    ServiceLogger.trackServiceState("CREATED")
    // ... rest of onCreate
}

override fun onDestroy() {
    ServiceLogger.recordServiceStop(this)
    ServiceLogger.trackServiceState("DESTROYED")
    // ... rest of onDestroy
    super.onDestroy()
}
```

---

## Google Play Store Compliance

Using persistent background services requires careful compliance with Google Play policies.

### Foreground Service Type Justification

| FGS Type | Play Store Requirement | Example Justification |
|----------|----------------------|----------------------|
| `specialUse` | Must declare `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` in manifest and explain during review | "Runs a local HTTP server for LAN device communication" |
| `dataSync` | Must demonstrate active data transfer | "Syncs offline changes to cloud when connectivity is available" |
| `mediaPlayback` | Must have active `MediaSession` | "Plays audio content selected by the user" |
| `location` | Must have active location use case | "Tracks delivery driver route for real-time customer updates" |

### Policy Checklist

1. **Battery optimization exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)**
   - Only allowed for apps whose **core function** requires persistent background operation
   - Examples: messaging apps, health monitoring, IoT controllers, navigation
   - Not allowed for: social media feeds, news apps, general utilities
   - If rejected, use in-app guidance to direct users to settings manually

2. **Foreground service notification**
   - Must accurately describe what the service is doing
   - Must not be misleading or deceptive
   - Must provide a way for the user to stop the service

3. **User consent**
   - User must explicitly start the background service (e.g., toggle in settings)
   - Auto-starting on boot is acceptable if the user previously enabled the service
   - Never start a foreground service without prior user action

4. **Data collection disclosure**
   - If your service collects location, network, or sensor data, declare it in the Data Safety section
   - Provide a privacy policy that covers background data collection

### Declaration Form (Play Console)

When submitting your app, you will need to fill out the **Foreground Service Permission** declaration form:

1. Navigate to **Play Console → App Content → Foreground service permission**
2. Select the foreground service types your app uses
3. For each type, provide:
   - A description of what the service does
   - Why it must run in the foreground
   - A video demonstrating the feature (recommended)
4. For `specialUse`, provide additional justification for why no other type fits

> **Tip:** Submit your FGS declaration early in the review process. Rejections can delay your release by 1–2 weeks.

---

## Troubleshooting Guide

### Common Issues and Solutions

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Service dies within 1 minute | Missing `startForeground()` call | Ensure `startForeground()` is called within 5 seconds of `onCreate()` |
| Service dies when screen off | Missing wake lock | Add `PARTIAL_WAKE_LOCK` with timeout |
| Service dies on app swipe | `stopWithTask` not set | Set `android:stopWithTask="false"` + implement `onTaskRemoved()` |
| Service not starting on boot | Missing `RECEIVE_BOOT_COMPLETED` permission | Add permission + register `BootReceiver` |
| Notification not showing (API 33+) | Missing `POST_NOTIFICATIONS` permission | Request runtime permission before starting service |
| Crash on API 34+ | Missing per-type FGS permission | Add `FOREGROUND_SERVICE_<TYPE>` permission to manifest |
| Service killed on Xiaomi/Huawei | OEM-specific battery optimization | Guide user through OEM settings (Tier 3) |
| Wake lock not held | Timeout expired without renewal | Implement periodic wake lock renewal |
| Wi-Fi unreachable in background | Missing Wi-Fi lock | Add `WifiLock` for LAN-accessible services |
| `dataSync` service stops after 6h | Android 15 timeout enforcement | Switch to `specialUse` or implement `onTimeout()` restart |
| Service restarts but loses state | Using `START_STICKY` (null intent on restart) | Save state to `SharedPreferences` or database; restore in `onCreate()` |
| `ForegroundServiceStartNotAllowedException` | Starting FGS from background (API 31+) | Use `WorkManager` or ensure an exemption applies (e.g., boot receiver, alarm) |

### API 31+ Background Start Restrictions

Starting in Android 12 (API 31), apps cannot start foreground services from the background except in specific cases:

**Allowed exemptions:**
- App has a visible activity
- App has a pending `PendingIntent` from a visible activity
- System broadcast receivers (`BOOT_COMPLETED`, etc.)
- Exact alarms (`AlarmManager.setExact()`)
- `WorkManager` expedited work
- Firebase Cloud Messaging high-priority messages
- App is in the temporary allowlist (e.g., after receiving a high-priority FCM)

**If you encounter `ForegroundServiceStartNotAllowedException`:**

```kotlin
fun safeStartForegroundService(context: Context, intent: Intent) {
    try {
        ContextCompat.startForegroundService(context, intent)
    } catch (e: ForegroundServiceStartNotAllowedException) {
        // Fallback: schedule with WorkManager for immediate execution
        Log.w(TAG, "Cannot start FGS from background, using WorkManager fallback")
        val workRequest = OneTimeWorkRequestBuilder<ServiceStartWorker>()
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueue(workRequest)
    } catch (e: Exception) {
        Log.e(TAG, "Failed to start foreground service: ${e.message}")
    }
}
```

---

## Quick Reference — Implementation Priority

Use this to decide what to implement based on your timeline:

### MVP (Minimum Viable Persistence) — Day 1

- [ ] Foreground service with notification (Tier 1, #1)
- [ ] `START_STICKY` return value (Tier 1, #2)
- [ ] Partial wake lock with timeout (Tier 1, #3)
- [ ] Notification permission request for API 33+ (Tier 1, #5)

### Production Ready — Week 1

- [ ] All MVP items
- [ ] Battery optimization exemption (Tier 1, #4)
- [ ] `stopWithTask="false"` (Tier 2, #6)
- [ ] `onTaskRemoved()` recovery (Tier 2, #7)
- [ ] `BOOT_COMPLETED` receiver (Tier 2, #8)
- [ ] WorkManager watchdog (Tier 2, #9A)

### Bulletproof — Week 2+

- [ ] All Production Ready items
- [ ] AlarmManager watchdog supplement (Tier 2, #9B)
- [ ] Wi-Fi lock for network services (Tier 2, #10)
- [ ] Android 15+ timeout handling (Tier 2, #11)
- [ ] OEM-specific guidance dialogs (Tier 3)
- [ ] ServiceLogger with uptime stats (Logging)
- [ ] Firebase Crashlytics integration (Logging)
- [ ] Automated persistence test script (Testing)
- [ ] Google Play compliance review (Compliance)

---
