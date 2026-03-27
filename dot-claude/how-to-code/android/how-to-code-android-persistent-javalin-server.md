# Android Javalin Server: Port Binding Issues & Recovery Strategies

> **A reusable guide for any Android app running an embedded Javalin HTTP server.**

---

## Table of Contents

- [Android Javalin Server: Port Binding Issues \& Recovery Strategies](#android-javalin-server-port-binding-issues--recovery-strategies)
  - [Table of Contents](#table-of-contents)
  - [The Problem](#the-problem)
  - [Why It Happens](#why-it-happens)
    - [The Lifecycle of a Zombie Socket](#the-lifecycle-of-a-zombie-socket)
    - [Common Triggers](#common-triggers)
  - [Solution 1: SO\_REUSEADDR (The Silver Bullet)](#solution-1-so_reuseaddr-the-silver-bullet)
    - [Javalin Configuration](#javalin-configuration)
  - [Solution 2: Retry Logic with Coroutines](#solution-2-retry-logic-with-coroutines)
    - [Full Service Template (Kotlin)](#full-service-template-kotlin)
    - [How It Works](#how-it-works)
  - [Solution 3: Java ExecutorService Alternative](#solution-3-java-executorservice-alternative)
  - [Handling Android Studio Hot Reload](#handling-android-studio-hot-reload)
    - [Why It's Different](#why-its-different)
    - [Hot Reload Recovery Strategy](#hot-reload-recovery-strategy)
    - [Key Differences from TIME\_WAIT Handling](#key-differences-from-time_wait-handling)
  - [Foreground Service Requirement](#foreground-service-requirement)
    - [Why It Matters](#why-it-matters)
    - [Implementation](#implementation)
    - [Foreground Service + Server Startup (Combined)](#foreground-service--server-startup-combined)
  - [Network Stability Considerations](#network-stability-considerations)
    - [Doze Mode \& Wi-Fi Sleep](#doze-mode--wi-fi-sleep)
    - [WifiLock (When Needed)](#wifilock-when-needed)
  - [Diagnostics \& Debugging](#diagnostics--debugging)
    - [ADB Commands](#adb-commands)
    - [Reading the Socket State](#reading-the-socket-state)
  - [Recovery Strategy Summary](#recovery-strategy-summary)
  - [Quick Checklist](#quick-checklist)
  - [TL;DR — The Minimal Fix](#tldr--the-minimal-fix)

---

## The Problem

When running a Javalin server inside an Android `Service`, you will inevitably encounter:

```
BindException: Address already in use
Port already in use. Make sure no other process is using port XXXX
Failed to bind to ::/[::]:XXXX
```

**The confusing part:** no other app is using that port. Your app is the *only* one. The culprit is your app's **own previous instance** — a zombie socket lingering in the OS's `TIME_WAIT` state after the process was killed.

---

## Why It Happens

### The Lifecycle of a Zombie Socket

| Time | Event |
|---|---|
| `T+0s` | App is running, Javalin server listening on port `XXXX`. |
| `T+1s` | Android Studio force-stops the app (or OOM killer strikes, or user swipes away). |
| `T+2s` | Process is dead, but the OS keeps the TCP socket in **TIME_WAIT** for 60–120 seconds. |
| `T+3s` | New app instance launches, tries to bind to port `XXXX` → **fails**. |
| `T+4s` | You run `lsof -i :XXXX` → **nothing shows up** (process is dead, but socket lingers). |

### Common Triggers

- **Android Studio "Run" button** — force-stops the app, zombie socket survives.
- **`START_STICKY` service restarts** — new service starts before old socket expires.
- **Process death** — OOM killer, crash, or user force-stop without graceful `onDestroy()`.
- **OEM aggressive battery optimization** — kills the process, watchdog restarts it too quickly.
- **Hot Reload / Apply Changes** — special case, covered [below](#handling-android-studio-hot-reload).

---

## Solution 1: SO_REUSEADDR (The Silver Bullet)

The `SO_REUSEADDR` socket option tells the OS to allow binding to a port that's in `TIME_WAIT`. This is the **first thing you should configure** — it eliminates the most common cause of the error.

### Javalin Configuration

Javalin uses Jetty under the hood. You must configure the `ServerConnector` on the underlying Jetty `Server`:

```kotlin
import io.javalin.Javalin
import org.eclipse.jetty.server.Server
import org.eclipse.jetty.server.ServerConnector

fun createJavalinServer(port: Int): Javalin {
    return Javalin.create { config ->
        config.jetty.server {
            val server = Server()
            val connector = ServerConnector(server).apply {
                this.port = port
                reuseAddress = true  // ← The key flag
            }
            server.addConnector(connector)
            server
        }
    }
}
```

> **Important:** `reuseAddress = true` must be set **before** the server starts. It only helps with `TIME_WAIT` sockets — it does **not** help when the same living process still holds the socket (see [Hot Reload](#handling-android-studio-hot-reload)).

---

## Solution 2: Retry Logic with Coroutines

Even with `SO_REUSEADDR`, you should have retry logic as a safety net. OEM quirks, aggressive killing, and edge cases can still cause transient bind failures.

> **🚨 Never use `Thread.sleep()` on the main thread.** Android Service lifecycle methods (`onStartCommand`, `onCreate`) run on the main thread. Blocking it causes ANR crashes.

### Full Service Template (Kotlin)

```kotlin
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import io.javalin.Javalin
import kotlinx.coroutines.*
import org.eclipse.jetty.server.Server
import org.eclipse.jetty.server.ServerConnector
import java.net.ServerSocket

class HttpServerService : Service() {

    companion object {
        private const val TAG = "HttpServerService"
        private const val SERVER_PORT = 8080
        private const val MAX_RETRIES = 3
        private const val RETRY_DELAY_MS = 1000L
    }

    private var javalinServer: Javalin? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startServerSafely()
        return START_STICKY
    }

    private fun startServerSafely() {
        serviceScope.launch {
            var retryCount = 0

            while (retryCount < MAX_RETRIES) {
                try {
                    Log.d(TAG, "Starting Javalin on port $SERVER_PORT (attempt ${retryCount + 1}/$MAX_RETRIES)")
                    cleanupServer()

                    javalinServer = createJavalinServer(SERVER_PORT).apply {
                        // ── Register your routes here ──
                        get("/health") { it.result("OK") }
                        // get("/api/...") { ... }
                    }
                    javalinServer?.start()

                    Log.d(TAG, "✓ Javalin started on port $SERVER_PORT")
                    return@launch

                } catch (e: Exception) {
                    retryCount++
                    if (isPortInUseError(e) && retryCount < MAX_RETRIES) {
                        Log.w(TAG, "Port $SERVER_PORT in use, retrying in ${RETRY_DELAY_MS}ms...")
                        delay(RETRY_DELAY_MS)
                    } else {
                        Log.e(TAG, "Failed to start Javalin after $retryCount attempts", e)
                        return@launch
                    }
                }
            }
        }
    }

    private fun createJavalinServer(port: Int): Javalin {
        return Javalin.create { config ->
            config.jetty.server {
                val server = Server()
                val connector = ServerConnector(server).apply {
                    this.port = port
                    reuseAddress = true
                }
                server.addConnector(connector)
                server
            }
        }
    }

    private fun cleanupServer() {
        try {
            javalinServer?.stop()
        } catch (e: Exception) {
            Log.w(TAG, "Cleanup error (ignored): ${e.message}")
        } finally {
            javalinServer = null
        }
    }

    private fun isPortInUseError(e: Exception): Boolean {
        val msg = e.message?.lowercase() ?: return false
        return msg.contains("port already in use") ||
               msg.contains("address already in use") ||
               msg.contains("bindexception") ||
               msg.contains("failed to bind")
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupServer()
        serviceScope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

### How It Works

1. **`serviceScope.launch`** moves all work off the main thread → no ANR risk.
2. **`cleanupServer()`** is called before every attempt to release any stale reference.
3. **`delay()`** is a non-blocking suspend function — the thread is freed while waiting.
4. **`serviceScope.cancel()`** in `onDestroy()` prevents leaked coroutines.
5. **`SO_REUSEADDR`** is set via `reuseAddress = true` on the Jetty connector.

---

## Solution 3: Java ExecutorService Alternative

If your project doesn't use Kotlin coroutines, use an `ExecutorService` to move retry logic off the main thread.

```java
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import io.javalin.Javalin;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.ServerConnector;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class HttpServerService extends Service {

    private static final String TAG = "HttpServerService";
    private static final int SERVER_PORT = 8080;
    private static final int MAX_RETRIES = 3;
    private static final long RETRY_DELAY_MS = 1000L;

    private Javalin javalinServer;
    private ExecutorService executor;

    @Override
    public void onCreate() {
        super.onCreate();
        executor = Executors.newSingleThreadExecutor();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startServerSafely();
        return START_STICKY;
    }

    private void startServerSafely() {
        executor.submit(() -> {
            int retryCount = 0;
            while (retryCount < MAX_RETRIES) {
                try {
                    Log.d(TAG, "Starting Javalin on port " + SERVER_PORT
                            + " (attempt " + (retryCount + 1) + "/" + MAX_RETRIES + ")");
                    cleanupServer();

                    javalinServer = createJavalinServer(SERVER_PORT);
                    // Register routes
                    javalinServer.get("/health", ctx -> ctx.result("OK"));

                    javalinServer.start();
                    Log.d(TAG, "✓ Javalin started on port " + SERVER_PORT);
                    return;

                } catch (Exception e) {
                    retryCount++;
                    if (isPortInUseError(e) && retryCount < MAX_RETRIES) {
                        Log.w(TAG, "Port " + SERVER_PORT + " in use, retrying in " + RETRY_DELAY_MS + "ms...");
                        try {
                            Thread.sleep(RETRY_DELAY_MS); // Safe — we're on the executor thread
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            return;
                        }
                    } else {
                        Log.e(TAG, "Failed after " + retryCount + " attempts", e);
                        return;
                    }
                }
            }
        });
    }

    private Javalin createJavalinServer(int port) {
        return Javalin.create(config -> {
            config.jetty.server(() -> {
                Server server = new Server();
                ServerConnector connector = new ServerConnector(server);
                connector.setPort(port);
                connector.setReuseAddress(true);
                server.addConnector(connector);
                return server;
            });
        });
    }

    private void cleanupServer() {
        if (javalinServer != null) {
            try { javalinServer.stop(); } catch (Exception ignored) {}
            javalinServer = null;
        }
    }

    private boolean isPortInUseError(Exception e) {
        String msg = e.getMessage();
        if (msg == null) return false;
        String lower = msg.toLowerCase();
        return lower.contains("port already in use")
            || lower.contains("address already in use")
            || lower.contains("bindexception")
            || lower.contains("failed to bind");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        cleanupServer();
        if (executor != null) executor.shutdownNow();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
```

---

## Handling Android Studio Hot Reload

**Hot Reload (Apply Changes) is a special case** that behaves completely differently from a normal restart.

### Why It's Different

| | Normal Restart (`Run`) | Hot Reload (`Apply Changes`) |
|---|---|---|
| Process | **Killed** and restarted | **Stays alive** (same PID) |
| Socket state | `TIME_WAIT` (zombie) | `LISTEN` (actively held) |
| `SO_REUSEADDR` helps? | ✅ Yes | ❌ No |
| `lsof` shows owner? | ❌ No (process dead) | ✅ Yes (your own PID) |

During hot reload:
1. The process **stays alive** (same PID).
2. `onDestroy()` is called on the old Service instance.
3. Native threads and sockets **survive** because the process didn't die.
4. `onCreate()` is called on a **new** Service instance.
5. The new instance tries to start Javalin → **fails** because the old socket is still bound.

### Hot Reload Recovery Strategy

```kotlin
private fun startServerSafely() {
    serviceScope.launch {
        // Phase 1: Detect and clean up zombie socket from hot reload
        if (!isPortAvailable(SERVER_PORT)) {
            Log.d(TAG, "Port $SERVER_PORT occupied — attempting cleanup...")
            cleanupServer()

            // Grace period: wait up to 500ms for graceful release
            val deadline = System.currentTimeMillis() + 500L
            while (System.currentTimeMillis() < deadline) {
                if (isPortAvailable(SERVER_PORT)) break
                delay(100)
            }

            // Force kill if still occupied
            if (!isPortAvailable(SERVER_PORT)) {
                Log.w(TAG, "Grace period expired — force stopping Jetty connectors")
                forceStopJettyConnectors()
                delay(200)
            }
        }

        // Phase 2: Start with exponential backoff
        val totalTimeout = 3000L
        val deadline = System.currentTimeMillis() + totalTimeout
        var attempt = 0

        while (System.currentTimeMillis() < deadline) {
            try {
                javalinServer = createJavalinServer(SERVER_PORT).apply {
                    get("/health") { it.result("OK") }
                }
                javalinServer?.start()
                Log.d(TAG, "✓ Javalin started on port $SERVER_PORT")
                return@launch
            } catch (e: Exception) {
                val backoff = 100L * (1 shl attempt++)
                Log.w(TAG, "Attempt ${attempt} failed, retrying in ${backoff}ms...")
                delay(backoff)
            }
        }

        Log.e(TAG, "✗ Failed to start Javalin within ${totalTimeout}ms")
    }
}

private fun isPortAvailable(port: Int): Boolean {
    return try {
        ServerSocket(port).use { true }
    } catch (e: Exception) {
        false
    }
}

private fun forceStopJettyConnectors() {
    try {
        javalinServer?.jettyServer()?.server()?.connectors?.forEach { connector ->
            try { connector.stop() } catch (ignored: Exception) {}
        }
        javalinServer?.stop()
    } catch (ignored: Exception) {}
    javalinServer = null
}
```

### Key Differences from TIME_WAIT Handling

| Aspect | TIME_WAIT Recovery | Hot Reload Recovery |
|---|---|---|
| First check | Reference nullity | **Port availability** (`isPortAvailable()`) |
| Cleanup | Graceful `stop()` | **Force kill** Jetty connectors |
| Grace period | 1000ms+ | 500ms (faster cleanup) |
| Retry strategy | Fixed delay | **Exponential backoff** (100→200→400→800ms) |

---

## Foreground Service Requirement

> **⚠️ This is critical for production.** Without a Foreground Service, Android (API 26+) will kill your background service within minutes of the app leaving the foreground. Your Javalin server will simply stop.

### Why It Matters

On Android 8.0 (API 26) and above, the system imposes **background execution limits**. A plain `Service` running in the background will be stopped by the OS shortly after the user navigates away. This means:

- Your Javalin server **will be killed** even if the code is perfect.
- `START_STICKY` will attempt to restart it, but the OS may throttle restarts.
- On some OEMs (Xiaomi, Huawei, Samsung), background services are killed even more aggressively.

A **Foreground Service** with a persistent notification tells the OS: "this service is doing visible, user-relevant work — don't kill it."

### Implementation

**1. Declare in `AndroidManifest.xml`:**

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<!-- API 34+ requires specifying the foreground service type -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<service
    android:name=".HttpServerService"
    android:foregroundServiceType="specialUse"
    android:exported="false" />
```

> **Note on `foregroundServiceType`:** Starting with Android 14 (API 34), you must declare a type. For a local HTTP server, `specialUse` is the appropriate category. On API 26–33, this attribute is optional but harmless to include.

**2. Create the notification channel and start as foreground (Kotlin):**

```kotlin
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class HttpServerService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "http_server_channel"
        // ... other constants
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Starting server..."))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "HTTP Server",
                NotificationManager.IMPORTANCE_LOW  // Low = no sound, minimal visual
            ).apply {
                description = "Keeps the local HTTP server running"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(contentText: String): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("HTTP Server")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Replace with your app icon
            .setOngoing(true)
            .build()
    }

    // Optional: update notification when server state changes
    private fun updateNotification(text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    // ... rest of the service (startServerSafely, cleanup, etc.)
}
```

**3. Start the service from your Activity or Application:**

```kotlin
// From an Activity or Application class:
val intent = Intent(this, HttpServerService::class.java)
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    startForegroundService(intent)
} else {
    startService(intent)
}
```

### Foreground Service + Server Startup (Combined)

Integrate the notification updates with the retry loop for a polished experience:

```kotlin
private fun startServerSafely() {
    serviceScope.launch {
        var retryCount = 0
        while (retryCount < MAX_RETRIES) {
            try {
                cleanupServer()
                javalinServer = createJavalinServer(SERVER_PORT).apply {
                    get("/health") { it.result("OK") }
                }
                javalinServer?.start()

                // Update notification on success
                withContext(Dispatchers.Main) {
                    updateNotification("Running on port $SERVER_PORT")
                }
                return@launch

            } catch (e: Exception) {
                retryCount++
                if (isPortInUseError(e) && retryCount < MAX_RETRIES) {
                    withContext(Dispatchers.Main) {
                        updateNotification("Port busy, retrying ($retryCount/$MAX_RETRIES)...")
                    }
                    delay(RETRY_DELAY_MS)
                } else {
                    withContext(Dispatchers.Main) {
                        updateNotification("Failed to start server")
                    }
                    return@launch
                }
            }
        }
    }
}
```

---

## Network Stability Considerations

If your Javalin server needs **high availability** (e.g., serving an AI model to other apps on the same device), be aware of Android's power-saving features that can disrupt networking even while your Foreground Service is alive.

### Doze Mode & Wi-Fi Sleep

- **Doze Mode** (API 23+): When the device is idle and unplugged, Android defers network access. Your server will still run, but **clients may not be able to reach it** if Wi-Fi is throttled.
- **Wi-Fi Sleep**: Some devices turn off Wi-Fi when the screen is off, making your server unreachable over the network.

### WifiLock (When Needed)

If your server must be reachable over Wi-Fi at all times (not just localhost):

```kotlin
import android.net.wifi.WifiManager

private var wifiLock: WifiManager.WifiLock? = null

private fun acquireWifiLock() {
    val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
    wifiLock = wifiManager.createWifiLock(
        WifiManager.WIFI_MODE_FULL_HIGH_PERF,
        "HttpServerService::WifiLock"
    ).apply {
        setReferenceCounted(false)
        acquire()
    }
}

private fun releaseWifiLock() {
    wifiLock?.let {
        if (it.isHeld) it.release()
    }
    wifiLock = null
}

// Call acquireWifiLock() in onCreate(), releaseWifiLock() in onDestroy()
```

> **When you DON'T need this:** If your server only serves `localhost` / `127.0.0.1` (same-device IPC), Wi-Fi state is irrelevant. Skip the WifiLock.

---

## Diagnostics & Debugging

### ADB Commands

```bash
# Check if anything is listening on your port
adb shell lsof -i :8080

# Show TIME_WAIT zombie sockets (may require root)
adb shell su -c "netstat -tan | grep 8080"

# Force-stop the app cleanly
adb shell am force-stop com.your.package

# Check socket state during hot reload
adb shell netstat -tan | grep 8080
# TIME_WAIT  → zombie socket from dead process (SO_REUSEADDR fixes this)
# LISTEN     → same process still owns it (hot reload scenario)
```

### Reading the Socket State

| State | Meaning | Fix |
|---|---|---|
| `TIME_WAIT` | Old process died, socket lingering | `SO_REUSEADDR` or wait 60–120s |
| `LISTEN` | Socket actively bound by a living process | Force-stop connectors, then rebind |
| `ESTABLISHED` | Active connection in progress | Graceful shutdown, then rebind |
| No output | Port is truly free | Something else is wrong — check your code |

---

## Recovery Strategy Summary

| Scenario | Primary Cause | Primary Fix | Fallback |
|---|---|---|---|
| **App Restart** (Android Studio `Run`) | Socket in `TIME_WAIT` | `SO_REUSEADDR` | Retry loop (1s delay) |
| **Hot Reload** (`Apply Changes`) | Same process holds `LISTEN` socket | Force-stop connectors + rebind | Exponential backoff (3s timeout) |
| **System Kill** (OOM / battery) | Process death + `START_STICKY` restart | `SO_REUSEADDR` + retry loop | Foreground Service to prevent kill |
| **OEM Aggressive Kill** | Vendor-specific background limits | Foreground Service + notification | Battery optimization whitelist |

---

## Quick Checklist

Before shipping your Android + Javalin app, verify:

- [ ] **`reuseAddress = true`** is set on the Jetty `ServerConnector`.
- [ ] **Server startup runs off the main thread** (coroutines or `ExecutorService`).
- [ ] **`cleanupServer()`** is called in `onDestroy()`.
- [ ] **`serviceScope.cancel()`** (or `executor.shutdownNow()`) is called in `onDestroy()`.
- [ ] **Retry logic** is in place with a reasonable max (3 attempts, 1s delay).
- [ ] **Hot reload** is handled with port-availability checks and force-stop fallback.
- [ ] **No `Thread.sleep()` on the main thread** — ever.
- [ ] **Foreground Service** with notification (required for API 26+ production).
- [ ] **`foregroundServiceType`** declared in manifest (required for API 34+).
- [ ] **WifiLock** acquired if server must be reachable over Wi-Fi (not needed for localhost).

---

## TL;DR — The Minimal Fix

If you just want the quickest solution, add these two things:

**1. Set `SO_REUSEADDR` on the Jetty connector:**

```kotlin
Javalin.create { config ->
    config.jetty.server {
        Server().also { server ->
            server.addConnector(ServerConnector(server).apply {
                port = YOUR_PORT
                reuseAddress = true
            })
        }
    }
}
```

**2. Wrap `start()` in a background retry loop:**

```kotlin
serviceScope.launch {
    repeat(3) { attempt ->
        try {
            server.start()
            return@launch
        } catch (e: Exception) {
            delay(1000L)
        }
    }
}
```

**3. Make it a Foreground Service** (for production):

```kotlin
override fun onCreate() {
    super.onCreate()
    createNotificationChannel()
    startForeground(NOTIFICATION_ID, buildNotification("Server running"))
}
```

These three changes will resolve 99% of port binding and service lifecycle issues in Android Javalin apps.