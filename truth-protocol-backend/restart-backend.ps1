# Restart Backend Server
# Stops any existing backend process and starts fresh

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Restarting Backend Server" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check for existing process on port 8080
Write-Host "[1/4] Checking for existing backend process..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

if ($portCheck) {
    $processId = $portCheck.OwningProcess
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

    if ($process) {
        Write-Host "  Found process: $($process.ProcessName) (PID: $processId)" -ForegroundColor Cyan
        Write-Host "  Stopping process..." -ForegroundColor Yellow

        try {
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "  ✓ Process stopped" -ForegroundColor Green
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "  ✗ Failed to stop process: $_" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "  No existing process found" -ForegroundColor Gray
}
Write-Host ""

# Step 2: Verify port is free
Write-Host "[2/4] Verifying port 8080 is free..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($portCheck) {
    Write-Host "  ✗ Port still in use!" -ForegroundColor Red
    Write-Host "  Please manually kill the process and try again" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "  ✓ Port 8080 is available" -ForegroundColor Green
}
Write-Host ""

# Step 3: Set environment variables
Write-Host "[3/4] Setting environment variables..." -ForegroundColor Yellow
$env:SPRING_PROFILES_ACTIVE = "dev"
$env:DB_PASSWORD = "55662211@@@"
$env:JWT_SECRET = "WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ=="
$env:POLYGON_RPC_URL = "https://polygon-rpc.com"
$env:POLYGON_CHAIN_ID = "80001"
Write-Host "  ✓ Environment configured" -ForegroundColor Green
Write-Host ""

# Step 4: Start the backend
Write-Host "[4/4] Starting backend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Backend Starting..." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Wait for the message:" -ForegroundColor Yellow
Write-Host "  'Started TruthProtocolApplication in X.XXX seconds'" -ForegroundColor White
Write-Host ""
Write-Host "Then in a NEW terminal window, run:" -ForegroundColor Cyan
Write-Host "  cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend" -ForegroundColor Gray
Write-Host "  .\test-login.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor DarkGray
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Start the backend
.\gradlew.bat bootRun --console=plain
