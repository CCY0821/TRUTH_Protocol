# Check if Backend is Running
# Tests if the TRUTH Protocol backend is responding

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Checking Backend Status" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check port 8080
Write-Host "Checking port 8080..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

if ($portCheck) {
    $processId = $portCheck.OwningProcess
    $process = Get-Process -Id $processId
    Write-Host "  Process on port 8080:" -ForegroundColor Cyan
    Write-Host "  - Name: $($process.ProcessName)" -ForegroundColor White
    Write-Host "  - PID: $processId" -ForegroundColor White
    Write-Host "  - Started: $($process.StartTime)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  No process on port 8080" -ForegroundColor Yellow
    Write-Host ""
}

# Test health endpoint
Write-Host "Testing backend health endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 3 -ErrorAction Stop

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  ✓ BACKEND IS RUNNING!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Health Status: $($health.status)" -ForegroundColor Cyan
    Write-Host "URL: http://localhost:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your backend is ready to use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Create/fix test user:" -ForegroundColor White
    Write-Host "     .\diagnose-login.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Test login:" -ForegroundColor White
    Write-Host "     .\test-login.ps1" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Backend is NOT responding" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""

    if ($portCheck) {
        Write-Host "A process is on port 8080 but not responding correctly." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  1. Kill the process and restart:" -ForegroundColor White
        Write-Host "     Stop-Process -Id $processId -Force" -ForegroundColor Gray
        Write-Host "     .\quick-start.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. Wait if backend is still starting up" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "Backend is not running." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Start it with:" -ForegroundColor Cyan
        Write-Host "  .\quick-start.ps1" -ForegroundColor White
        Write-Host ""
    }
}
