# Quick Start - TRUTH Protocol Backend
# This script performs all necessary checks and starts the backend

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  TRUTH Protocol - Quick Start" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if PostgreSQL is running
Write-Host "[1/5] Checking PostgreSQL database..." -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$dbCheck = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT 1;" -t 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "    ✗ PostgreSQL is NOT running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Please start PostgreSQL service:" -ForegroundColor Yellow
    Write-Host "    Start-Service -Name postgresql-x64-*" -ForegroundColor White
    Write-Host ""
    Remove-Item Env:\PGPASSWORD
    exit 1
}

Remove-Item Env:\PGPASSWORD
Write-Host ""

# Step 2: Check if users table exists
Write-Host "[2/5] Checking database schema..." -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$tableCheck = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users');" -t 2>&1

if ($tableCheck -match "t") {
    Write-Host "    ✓ Database schema exists" -ForegroundColor Green
} else {
    Write-Host "    ✗ Users table not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Database migration may not have run." -ForegroundColor Yellow
    Write-Host "    This will be initialized on first startup." -ForegroundColor White
}

Remove-Item Env:\PGPASSWORD
Write-Host ""

# Step 3: Check if Gradle wrapper exists
Write-Host "[3/5] Checking Gradle wrapper..." -ForegroundColor Yellow
if (Test-Path ".\gradlew.bat") {
    Write-Host "    ✓ Gradle wrapper found" -ForegroundColor Green
} else {
    Write-Host "    ✗ Gradle wrapper not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Please ensure you're in the project directory:" -ForegroundColor Yellow
    Write-Host "    cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# Step 4: Check if port 8080 is available
Write-Host "[4/5] Checking port 8080..." -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

if ($portCheck) {
    Write-Host "    ⚠ Port 8080 is already in use!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Process occupying port 8080:" -ForegroundColor Cyan
    $processId = $portCheck.OwningProcess
    Get-Process -Id $processId | Format-Table -Property Id, ProcessName, StartTime
    Write-Host ""

    $response = Read-Host "    Kill this process and continue? (y/n)"
    if ($response -eq 'y') {
        Stop-Process -Id $processId -Force
        Write-Host "    ✓ Process terminated" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "    Please manually stop the process on port 8080" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "    ✓ Port 8080 is available" -ForegroundColor Green
}
Write-Host ""

# Step 5: Set environment variables and start
Write-Host "[5/5] Starting backend server..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Setting environment variables..." -ForegroundColor Cyan
$env:SPRING_PROFILES_ACTIVE = "dev"
$env:DB_PASSWORD = "55662211@@@"
$env:JWT_SECRET = "WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ=="
$env:POLYGON_RPC_URL = "https://polygon-rpc.com"
$env:POLYGON_CHAIN_ID = "80001"

Write-Host "Environment configured:" -ForegroundColor Cyan
Write-Host "  SPRING_PROFILES_ACTIVE = dev" -ForegroundColor Gray
Write-Host "  DB_PASSWORD = ***" -ForegroundColor Gray
Write-Host "  JWT_SECRET = ***" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "  Starting Spring Boot Application..." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Please wait for the message:" -ForegroundColor Yellow
Write-Host "  'Started TruthProtocolApplication in X.XXX seconds'" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Start the application
.\gradlew.bat bootRun --console=plain
