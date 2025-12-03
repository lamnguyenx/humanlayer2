# Android Logcat Level Guide for AI Agents

## Log Level Indicators

When analyzing Android Studio logcat output, the single letter indicates the log level:

| Letter | Level | Meaning |
|--------|-------|---------|
| **V** | Verbose | Most detailed logging (lowest priority) |
| **D** | Debug | Debug messages for development |
| **I** | Info | General informational messages |
| **W** | Warning | Potential issues, app continues running |
| **E** | Error | Error events, app may continue |
| **A** | Assert | Critical failures (highest priority) |

## Logcat Format Structure

**Most common format** (package names disabled):
```
 [Level]  [Message]
```

**Example:**
```
 D  MainActivity: onCreate() called
 D  NetworkManager: Initializing connection pool
 I  Application started successfully
 I  User logged in: user_id=12345
 W  NetworkManager: Connection timeout, retrying...
 W  CacheManager: Cache size exceeding 80% threshold
 E  DatabaseHelper: Failed to open database
    java.sql.SQLException: unable to open database file
 E  ImageLoader: Out of memory error
    at com.example.app.ImageLoader.loadBitmap(ImageLoader.java:45)
 A  CriticalService: Fatal error - app cannot continue
```

**With package names enabled + "Show repeated package name" disabled:**
```
com.example.app1          D  MainActivity: onCreate() called
                          D  NetworkManager: Initializing connection pool
                          I  Application started successfully
                          I  User logged in: user_id=12345
com.example.app2          W  CacheManager: Cache size exceeding 80% threshold
                          W  NetworkManager: Connection timeout, retrying...
                          E  DatabaseHelper: Failed to open database
                             java.sql.SQLException: unable to open database file
com.example.app1          E  ImageLoader: Out of memory error
                             at com.example.app.ImageLoader.loadBitmap(ImageLoader.java:45)
```

**With "Show repeated package name" enabled:**
```
com.example.app1          D  MainActivity: onCreate() called
com.example.app1          D  NetworkManager: Initializing connection pool
com.example.app1          I  Application started successfully
com.example.app1          I  User logged in: user_id=12345
com.example.app2          W  CacheManager: Cache size exceeding 80% threshold
com.example.app2          W  NetworkManager: Connection timeout, retrying...
com.example.app2          E  DatabaseHelper: Failed to open database
                             java.sql.SQLException: unable to open database file
com.example.app1          E  ImageLoader: Out of memory error
                             at com.example.app.ImageLoader.loadBitmap(ImageLoader.java:45)
```

## Analysis Priority

1. **E/A** - Critical issues (check first)
2. **W** - Warnings (potential problems)
3. **I** - App flow information
4. **D/V** - Detailed debugging info

## Priority Order
```
V < D < I < W < E < A (lowest to highest)
```

---

**Quick Reference:** V=Verbose | D=Debug | I=Info | W=Warning | E=Error | A=Assert