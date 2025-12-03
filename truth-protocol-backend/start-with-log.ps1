# Start Backend and Save Complete Log
# Captures full startup log for debugging

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Starting Backend with Log Capture" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Set environment variables
$env:SPRING_PROFILES_ACTIVE = "dev"
$env:DB_PASSWORD = "55662211@@@"
$env:JWT_SECRET = "WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ=="
$env:POLYGON_RPC_URL = "https://polygon-rpc.com"
$env:POLYGON_CHAIN_ID = "80001"
$env:SPRING_DEVTOOLS_RESTART_ENABLED = "false"

Write-Host "Environment configured" -ForegroundColor Green
Write-Host "Starting backend..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Log will be saved to: startup.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please wait 30-60 seconds for startup..." -ForegroundColor Yellow
Write-Host ""

# Start backend and capture log
$logFile = "startup.log"
.\gradlew.bat bootRun 2>&1 | Tee-Object -FilePath $logFile
