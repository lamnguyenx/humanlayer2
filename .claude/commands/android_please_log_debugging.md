You are an Android debugging assistant. I’m encountering [ERROR/ISSUE] in my Android app. Please propose and show code changes to add targeted diagnostics that I can copy-paste.

Goals:
1) Insert Log.d() statements at key execution points:
   - Entry/exit of public methods and critical code paths
   - Before/after network calls, DB ops, file I/O, and IPC
   - Before/after conditional branches and early returns

2) Print object state with null safety:
   - For each relevant object/param: log isNull, class, hashCode, and key fields
   - Prefer safe rendering (toString guarded) to avoid NPE and heavy logs
   - For Bundles/Intents: log extras keys/types and a few representative values

3) Track Android lifecycle:
   - In Activities/Fragments/ViewModels/Services: add logs to onCreate/onStart/onResume/onPause/onStop/onDestroy, onAttach/onDetach, onViewCreated/onDestroyView, onCleared
   - Include instance identity (this.hashCode()) and savedInstanceState presence

4) Log threading/coroutine context:
   - Include thread name/id: Thread.currentThread().name
   - For coroutines: log coroutineContext (Dispatcher, Job, isActive), and scope identity
   - Around withContext/launch: log before/after with dispatcher info

5) Collections logging:
   - Log size, isEmpty, and up to first N sample items (e.g., 3)
   - For large collections, avoid full dumps; truncate with “…(N of size=XYZ)”
   - For maps: sample a few key→value pairs; mask sensitive data

6) Error and exception handling:
   - Wrap risky blocks; on catch, log message, cause, and stacktrace (Log.e with e)
   - Add a unique tag prefix and correlationId to tie related logs together

7) Performance and timing:
   - Add timing markers and durations (SystemClock.elapsedRealtime()) around slow ops

8) Privacy and safety:
   - Do not log PII, tokens, passwords, or full payloads; mask or hash when needed

Deliverables:
- Show concrete code diffs/snippets for:
  - One Activity (lifecycle + intent extras)
  - One Fragment (view lifecycle)
  - One Repository/UseCase (network/DB with coroutines)
- Provide a small Log helper utility (Kotlin) with:
  - tag creation, safeToString(obj), sampleCollection(collection, limit=3)
  - contextLog(): thread + coroutine details
  - time block helper: time(tag, label) { … }
- Include a sample log output illustrating the format around a failing flow

Assumptions:
- Kotlin project using coroutines; Android minSDK XX
- Use Log.d for verbose info, Log.w for anomalies, Log.e for errors

Replace [ERROR/ISSUE] with my specific problem and reference the related classes/files.
