# Diagnose Backend Startup Issues
# This script checks all common startup problems

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Backend Startup Diagnostics" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()

# Check 1: Java Installation
Write-Host "[Check 1/8] Java Installation" -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    if ($javaVersion -match "17") {
        Write-Host "  ✓ Java 17 found: $javaVersion" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Java version: $javaVersion" -ForegroundColor Yellow
        $warnings += "Java 17 is recommended, but found: $javaVersion"
    }
} catch {
    Write-Host "  ✗ Java not found!" -ForegroundColor Red
    $issues += "Java is not installed or not in PATH"
}
Write-Host ""

# Check 2: PostgreSQL Service
Write-Host "[Check 2/8] PostgreSQL Service" -ForegroundColor Yellow
$pgService = Get-Service -Name postgresql* -ErrorAction SilentlyContinue
if ($pgService) {
    if ($pgService.Status -eq "Running") {
        Write-Host "  ✓ PostgreSQL service is running" -ForegroundColor Green
    } else {
        Write-Host "  ✗ PostgreSQL service is stopped" -ForegroundColor Red
        $issues += "PostgreSQL service is not running: $($pgService.Status)"
    }
} else {
    Write-Host "  ✗ PostgreSQL service not found" -ForegroundColor Red
    $issues += "PostgreSQL is not installed"
}
Write-Host ""

# Check 3: Database Connection
Write-Host "[Check 3/8] Database Connection" -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$dbTest = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT version();" -t 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Database connection successful" -ForegroundColor Green
    Write-Host "  $($dbTest.Trim())" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Cannot connect to database" -ForegroundColor Red
    Write-Host "  Error: $dbTest" -ForegroundColor Gray
    $issues += "Database connection failed: $dbTest"
}
Remove-Item Env:\PGPASSWORD
Write-Host ""

# Check 4: Database Schema
Write-Host "[Check 4/8] Database Schema (users table)" -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$tableCheck = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'users';" -t 2>&1
if ($tableCheck -match "1") {
    Write-Host "  ✓ Users table exists" -ForegroundColor Green

    # Check if there are any users
    $userCount = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT COUNT(*) FROM users;" -t 2>&1
    Write-Host "  Users in database: $($userCount.Trim())" -ForegroundColor Gray
} else {
    Write-Host "  ⚠ Users table does not exist" -ForegroundColor Yellow
    $warnings += "Users table not found - will be created on first startup by Flyway"
}
Remove-Item Env:\PGPASSWORD
Write-Host ""

# Check 5: Gradle Wrapper
Write-Host "[Check 5/8] Gradle Wrapper" -ForegroundColor Yellow
if (Test-Path ".\gradlew.bat") {
    Write-Host "  ✓ Gradle wrapper found" -ForegroundColor Green

    # Try to get Gradle version
    try {
        $gradleVersion = .\gradlew.bat --version 2>&1 | Select-String "Gradle"
        Write-Host "  $gradleVersion" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠ Cannot determine Gradle version" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Gradle wrapper not found" -ForegroundColor Red
    $issues += "gradlew.bat not found in current directory"
}
Write-Host ""

# Check 6: Port 8080 Availability
Write-Host "[Check 6/8] Port 8080 Availability" -ForegroundColor Yellow
$portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($portCheck) {
    Write-Host "  ✗ Port 8080 is already in use" -ForegroundColor Red
    $processId = $portCheck.OwningProcess
    $process = Get-Process -Id $processId
    Write-Host "  Process: $($process.ProcessName) (PID: $processId)" -ForegroundColor Gray
    $issues += "Port 8080 is occupied by $($process.ProcessName) (PID: $processId)"
} else {
    Write-Host "  ✓ Port 8080 is available" -ForegroundColor Green
}
Write-Host ""

# Check 7: Configuration Files
Write-Host "[Check 7/8] Configuration Files" -ForegroundColor Yellow
$configFiles = @(
    "src\main\resources\application.yml",
    "src\main\resources\application-dev.yml",
    "build.gradle"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file missing" -ForegroundColor Red
        $issues += "Configuration file missing: $file"
    }
}
Write-Host ""

# Check 8: Build Status
Write-Host "[Check 8/8] Project Build Status" -ForegroundColor Yellow
if (Test-Path "build\classes\java\main\com\truthprotocol\TruthProtocolApplication.class") {
    Write-Host "  ✓ Application class compiled" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Application not compiled yet" -ForegroundColor Yellow
    $warnings += "Project needs to be built (will happen automatically on bootRun)"
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Diagnostic Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your environment is ready. Start the backend with:" -ForegroundColor Cyan
    Write-Host "  .\quick-start.ps1" -ForegroundColor White
    Write-Host ""
} else {
    if ($issues.Count -gt 0) {
        Write-Host "Critical Issues Found:" -ForegroundColor Red
        $i = 1
        foreach ($issue in $issues) {
            Write-Host "  $i. $issue" -ForegroundColor White
            $i++
        }
        Write-Host ""
    }

    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        $i = 1
        foreach ($warning in $warnings) {
            Write-Host "  $i. $warning" -ForegroundColor White
            $i++
        }
        Write-Host ""
    }

    Write-Host "Recommended Actions:" -ForegroundColor Cyan
    Write-Host ""

    if ($issues -match "PostgreSQL") {
        Write-Host "→ PostgreSQL Issues:" -ForegroundColor Yellow
        Write-Host "  1. Install PostgreSQL if not installed" -ForegroundColor White
        Write-Host "  2. Start PostgreSQL service:" -ForegroundColor White
        Write-Host "     Start-Service -Name postgresql-x64-*" -ForegroundColor Gray
        Write-Host "  3. Verify connection:" -ForegroundColor White
        Write-Host "     .\test-db-connection.ps1" -ForegroundColor Gray
        Write-Host ""
    }

    if ($issues -match "Java") {
        Write-Host "→ Java Issues:" -ForegroundColor Yellow
        Write-Host "  1. Install Java 17 (Eclipse Temurin recommended)" -ForegroundColor White
        Write-Host "  2. Add Java to PATH environment variable" -ForegroundColor White
        Write-Host "  3. Verify: java -version" -ForegroundColor Gray
        Write-Host ""
    }

    if ($issues -match "Port 8080") {
        Write-Host "→ Port Issues:" -ForegroundColor Yellow
        Write-Host "  1. Kill the process using port 8080:" -ForegroundColor White
        $portCheck = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
        if ($portCheck) {
            $processId = $portCheck.OwningProcess
            Write-Host "     Stop-Process -Id $processId -Force" -ForegroundColor Gray
        }
        Write-Host "  2. Or use quick-start.ps1 which will handle this automatically" -ForegroundColor White
        Write-Host ""
    }

    if ($issues -match "gradlew.bat") {
        Write-Host "→ Directory Issues:" -ForegroundColor Yellow
        Write-Host "  1. Make sure you're in the correct directory:" -ForegroundColor White
        Write-Host "     cd C:\Users\G512LV\TRUTH_Protocol\truth-protocol-backend" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "For more help, see:" -ForegroundColor Cyan
Write-Host "  .\STARTUP-INSTRUCTIONS.md" -ForegroundColor White
Write-Host ""
