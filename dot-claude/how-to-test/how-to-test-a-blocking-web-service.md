# Guide for AI Agent: Testing Blocking Web Services in Single-Shell Environments

## Context
You are operating in a constrained environment where:
- Only ONE shell session is available
- No terminal multiplexers (tmux, screen) can be used
- No Docker or containerization
- The web service blocks the shell when running

## Core Strategy: Background Execution with `&`

### Basic Pattern
```bash
SERVICE_PORT=8080
# Start service in background
./web-service &
SERVICE_PID=$!

# Test the service
curl http://localhost:${SERVICE_PORT}

# Stop the service
kill $SERVICE_PID
```

## Step-by-Step Implementation Guide

### 1. Pre-flight Checks
Before starting the service, verify the environment:

```bash
SERVICE_PORT=8080
# Check if port is available
lsof -i:${SERVICE_PORT} || netstat -an | grep ${SERVICE_PORT}

# Check if service executable exists
test -f ./web-service || echo "Service not found!"

# Check current directory
pwd
```

### 2. Start Service with Proper Logging
```bash
# Create log file with timestamp
LOG_FILE="service_$(date +%Y%m%d_%H%M%S).log"

# Start service with output redirection
./web-service > "$LOG_FILE" 2>&1 &
SERVICE_PID=$!

# Verify process started
ps -p $SERVICE_PID || echo "Failed to start service"
```

### 3. Wait for Service Readiness
```bash
SERVICE_PORT=8080
# Method 1: Port check with timeout
TIMEOUT=30
ELAPSED=0
while ! nc -z localhost ${SERVICE_PORT} && [ $ELAPSED -lt $TIMEOUT ]; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# Method 2: Health endpoint check
while ! curl -s http://localhost:${SERVICE_PORT}/health > /dev/null; do
    sleep 1
done
```

### 4. Execute Tests
```bash
SERVICE_PORT=8080
# Run HTTP test commands
curl -X GET http://localhost:${SERVICE_PORT}/api/users
curl -X POST http://localhost:${SERVICE_PORT}/api/users -d '{"name":"test"}'
curl -X DELETE http://localhost:${SERVICE_PORT}/api/users/1

# Save test results
curl http://localhost:${SERVICE_PORT}/api/status > test_results.json

# WebSocket Testing (Optional)
# Using websocat (install if needed: brew install websocat or apt install websocat)
echo '{"type": "ping"}' | websocat ws://localhost:${SERVICE_PORT}/ws

# Alternative using wscat (if npm is available)
# npm install -g wscat
# wscat -c ws://localhost:${SERVICE_PORT}/ws -x '{"type": "test"}'
```

### 5. Cleanup
```bash
# Stop the service
kill $SERVICE_PID

# Wait for process to terminate
wait $SERVICE_PID 2>/dev/null

# Check if process is truly gone
ps -p $SERVICE_PID && kill -9 $SERVICE_PID
```

## Complete Test Script Template

```bash
#!/bin/bash
# test_blocking_service.sh

# Configuration
SERVICE_CMD="./web-service"
SERVICE_PORT=8080
LOG_FILE="service.log"
MAX_WAIT=30

# Start service
echo "[1/5] Starting service..."
$SERVICE_CMD > $LOG_FILE 2>&1 &
SERVICE_PID=$!

# Check if service started
if ! ps -p $SERVICE_PID > /dev/null; then
    echo "ERROR: Service failed to start"
    cat $LOG_FILE
    exit 1
fi

echo "[2/5] Service PID: $SERVICE_PID"

# Wait for service to be ready
echo "[3/5] Waiting for service on port $SERVICE_PORT..."
COUNTER=0
while ! nc -z localhost $SERVICE_PORT; do
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo "ERROR: Service not ready after $MAX_WAIT seconds"
        kill $SERVICE_PID
        cat $LOG_FILE
        exit 1
    fi
    echo -n "."
done
echo " Ready!"

# Run tests
echo "[4/5] Running tests..."
curl -s http://localhost:$SERVICE_PORT/test1
curl -s http://localhost:$SERVICE_PORT/test2

# Cleanup
echo "[5/5] Stopping service..."
kill $SERVICE_PID
wait $SERVICE_PID 2>/dev/null

echo "Test completed. Check $LOG_FILE for service output."
```

## Decision Tree for AI Agent

```
START
│
├─ Is service already running?
│  ├─ YES → Kill existing process first
│  └─ NO → Continue
│
├─ Start service with & operator
│  └─ Capture PID immediately
│
├─ Is service responsive?
│  ├─ NO → Wait and retry (with timeout)
│  └─ YES → Proceed with tests
│
├─ Run test commands
│  └─ Capture outputs if needed
│
└─ Cleanup
   ├─ Send SIGTERM (kill $PID)
   ├─ Wait for termination
   └─ Force kill if necessary (kill -9)
```

## Important Patterns to Remember

### Pattern 1: Inline Testing
```bash
SERVICE_PORT=8080
# One-liner for quick tests
./web-service & PID=$! && sleep 2 && curl localhost:${SERVICE_PORT} && kill $PID
```

### Pattern 2: Subshell Isolation
```bash
SERVICE_PORT=8080
# Everything in a subshell - automatic cleanup
(./web-service & PID=$!; sleep 2; curl localhost:${SERVICE_PORT}; kill $PID)
```

### Pattern 3: Error Handling
```bash
# With error handling
./web-service & PID=$! || { echo "Failed to start"; exit 1; }
trap "kill $PID 2>/dev/null" EXIT
# ... run tests ...
```

## Common Issues and Solutions

1. **Port Already in Use**
   ```bash
   SERVICE_PORT=8080
   # Find and kill process using port
   lsof -ti:${SERVICE_PORT} | xargs kill -9
   ```

2. **Service Doesn't Stop**
   ```bash
   # Escalate from SIGTERM to SIGKILL
   kill $PID || kill -9 $PID
   ```

3. **Can't Find Process**
   ```bash
   # Use pgrep if PID is lost
   pgrep -f "web-service" | xargs kill
   ```

## Key Commands for AI Agent

- Start background process: `command &`
- Capture PID: `PID=$!`
- Check process: `ps -p $PID`
- Check port: `nc -z localhost ${SERVICE_PORT}`
- Stop process: `kill $PID`
- Force stop: `kill -9 $PID`
- Wait for process: `wait $PID`

## Final Note
Always ensure cleanup happens, even if tests fail. The background process MUST be terminated to free resources and ports for subsequent operations.