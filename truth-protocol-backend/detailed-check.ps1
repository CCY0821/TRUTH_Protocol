# Detailed Backend Check
# Performs comprehensive check of backend status

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Detailed Backend Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Port 8080
Write-Host "[1/5] Checking port 8080..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue

if ($portCheck) {
    $processId = $portCheck.OwningProcess
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    Write-Host "  ✓ Port 8080 is LISTENING" -ForegroundColor Green
    Write-Host "  Process: $($process.ProcessName) (PID: $processId)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Port 8080 is NOT listening" -ForegroundColor Red
}
Write-Host ""

# Check 2: All Java processes
Write-Host "[2/5] Checking Java processes..." -ForegroundColor Yellow
$javaProcesses = Get-Process -Name java -ErrorAction SilentlyContinue
if ($javaProcesses) {
    foreach ($proc in $javaProcesses) {
        Write-Host "  Java process found:" -ForegroundColor Cyan
        Write-Host "    PID: $($proc.Id)" -ForegroundColor Gray
        Write-Host "    Started: $($proc.StartTime)" -ForegroundColor Gray
        Write-Host "    CPU Time: $($proc.CPU)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No Java processes found" -ForegroundColor Yellow
}
Write-Host ""

# Check 3: Test basic HTTP connection
Write-Host "[3/5] Testing HTTP connection to localhost:8080..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✓ HTTP connection successful (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ✗ HTTP connection failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
}
Write-Host ""

# Check 4: Test health endpoint
Write-Host "[4/5] Testing /actuator/health endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✓ Health endpoint responding" -ForegroundColor Green
    Write-Host "  Status: $($health.status)" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  ✗ Health endpoint failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
    if ($statusCode) {
        Write-Host "  Status Code: $statusCode" -ForegroundColor Gray
    }
}
Write-Host ""

# Check 5: Test login endpoint
Write-Host "[5/5] Testing /api/v1/auth/login endpoint..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email = "test@example.com"
        password = "test"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -TimeoutSec 3 `
        -ErrorAction Stop

    Write-Host "  ✓ Login endpoint responding (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__

    if ($statusCode -eq 401) {
        Write-Host "  ✓ Login endpoint is working (401 Unauthorized is expected for invalid credentials)" -ForegroundColor Green
    } elseif ($statusCode -eq 404) {
        Write-Host "  ✗ Login endpoint not found (404)" -ForegroundColor Red
    } else {
        Write-Host "  ⚠ Login endpoint responded with status: $statusCode" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Final recommendation
$portListening = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue

if ($portListening) {
    Write-Host "Backend appears to be running." -ForegroundColor Green
    Write-Host ""
    Write-Host "If health check failed, the backend may still be starting up." -ForegroundColor Yellow
    Write-Host "Please check the backend console window for:" -ForegroundColor Cyan
    Write-Host "  - 'Started TruthProtocolApplication in X.XXX seconds'" -ForegroundColor White
    Write-Host "  - Any error messages" -ForegroundColor White
    Write-Host ""
    Write-Host "Once you see the startup message, try:" -ForegroundColor Cyan
    Write-Host "  .\test-login.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Backend is NOT running on port 8080." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the backend with:" -ForegroundColor Cyan
    Write-Host "  .\start-dev.ps1" -ForegroundColor White
    Write-Host ""
}
