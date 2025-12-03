# Cleanup All Java Processes
# Stops all Java processes to clean up stuck backends

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Java Process Cleanup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Find all Java processes
$javaProcesses = Get-Process -Name java -ErrorAction SilentlyContinue

if (-not $javaProcesses) {
    Write-Host "No Java processes found." -ForegroundColor Green
    Write-Host ""
    Write-Host "You can start the backend with:" -ForegroundColor Cyan
    Write-Host "  .\start-dev.ps1" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Display all Java processes
Write-Host "Found $($javaProcesses.Count) Java process(es):" -ForegroundColor Yellow
Write-Host ""

$i = 1
foreach ($proc in $javaProcesses) {
    Write-Host "  [$i] PID: $($proc.Id)" -ForegroundColor Cyan
    Write-Host "      Started: $($proc.StartTime)" -ForegroundColor Gray
    Write-Host "      CPU Time: $($proc.CPU)s" -ForegroundColor Gray
    Write-Host "      Memory: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host ""
    $i++
}

# Ask for confirmation
Write-Host "This will stop ALL Java processes." -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Do you want to continue? (y/n)"

if ($response -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Stopping all Java processes..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($proc in $javaProcesses) {
    try {
        Write-Host "  Stopping PID $($proc.Id)..." -ForegroundColor Cyan
        Stop-Process -Id $proc.Id -Force -ErrorAction Stop
        Write-Host "  ✓ Stopped PID $($proc.Id)" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "  ✗ Failed to stop PID $($proc.Id): $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stopped: $successCount processes" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount processes" -ForegroundColor Red
}
Write-Host ""

# Wait for processes to fully terminate
Write-Host "Waiting for processes to terminate..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Verify port 8080 is free
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($portCheck) {
    Write-Host "⚠ Port 8080 is still in use" -ForegroundColor Yellow
    Write-Host "  You may need to wait a few more seconds" -ForegroundColor Gray
} else {
    Write-Host "✓ Port 8080 is now free" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Start the backend:" -ForegroundColor White
Write-Host "     .\start-dev.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Wait for startup message:" -ForegroundColor White
Write-Host "     'Started TruthProtocolApplication in X.XXX seconds'" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Test login in a new window:" -ForegroundColor White
Write-Host "     .\test-login.ps1" -ForegroundColor Gray
Write-Host ""
