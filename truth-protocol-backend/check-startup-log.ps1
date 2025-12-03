# Check Startup Log for Issues
# Analyzes the startup.log file

$logFile = "startup.log"

if (-not (Test-Path $logFile)) {
    Write-Host "Log file not found: $logFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: .\start-with-log.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Analyzing Startup Log" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$content = Get-Content $logFile -Raw

# Check for startup success
Write-Host "[1/5] Checking for successful startup..." -ForegroundColor Yellow
if ($content -match "Started TruthProtocolApplication") {
    Write-Host "  ✓ Application started successfully" -ForegroundColor Green
    $startedLine = Select-String -Path $logFile -Pattern "Started TruthProtocolApplication"
    Write-Host "  $($startedLine.Line)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ 'Started TruthProtocolApplication' not found" -ForegroundColor Red
}
Write-Host ""

# Check for Tomcat
Write-Host "[2/5] Checking Tomcat startup..." -ForegroundColor Yellow
if ($content -match "Tomcat started") {
    Write-Host "  ✓ Tomcat started" -ForegroundColor Green
    $tomcatLine = Select-String -Path $logFile -Pattern "Tomcat started"
    Write-Host "  $($tomcatLine.Line)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ 'Tomcat started' not found" -ForegroundColor Red
}
Write-Host ""

# Check for errors
Write-Host "[3/5] Checking for errors..." -ForegroundColor Yellow
$errors = Select-String -Path $logFile -Pattern "ERROR" -Context 0,2
if ($errors) {
    Write-Host "  ⚠ Found $($errors.Count) error(s)" -ForegroundColor Yellow
    Write-Host ""
    foreach ($error in $errors | Select-Object -First 5) {
        Write-Host "  $($error.Line)" -ForegroundColor Red
    }
} else {
    Write-Host "  ✓ No errors found" -ForegroundColor Green
}
Write-Host ""

# Check for exceptions
Write-Host "[4/5] Checking for exceptions..." -ForegroundColor Yellow
$exceptions = Select-String -Path $logFile -Pattern "Exception" -Context 1,3
if ($exceptions) {
    Write-Host "  ⚠ Found $($exceptions.Count) exception(s)" -ForegroundColor Yellow
    Write-Host ""
    foreach ($exception in $exceptions | Select-Object -First 3) {
        Write-Host "  $($exception.Line)" -ForegroundColor Red
        foreach ($contextLine in $exception.Context.PostContext) {
            Write-Host "  $contextLine" -ForegroundColor Gray
        }
        Write-Host ""
    }
} else {
    Write-Host "  ✓ No exceptions found" -ForegroundColor Green
}
Write-Host ""

# Check for security filter chain
Write-Host "[5/5] Checking Security configuration..." -ForegroundColor Yellow
if ($content -match "SecurityFilterChain" -or $content -match "security filter") {
    Write-Host "  ✓ Security filter chain initialized" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Security filter chain info not found" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$hasStarted = $content -match "Started TruthProtocolApplication"
$hasTomcat = $content -match "Tomcat started"
$hasErrors = $errors -ne $null
$hasExceptions = $exceptions -ne $null

if ($hasStarted -and $hasTomcat -and -not $hasErrors) {
    Write-Host "✓ Backend started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now test login:" -ForegroundColor Cyan
    Write-Host "  .\simple-login-test.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Backend startup incomplete or has issues:" -ForegroundColor Yellow
    Write-Host ""

    if (-not $hasStarted) {
        Write-Host "  - Application did not finish starting" -ForegroundColor Red
    }
    if (-not $hasTomcat) {
        Write-Host "  - Tomcat did not start" -ForegroundColor Red
    }
    if ($hasErrors) {
        Write-Host "  - Errors detected (see above)" -ForegroundColor Red
    }
    if ($hasExceptions) {
        Write-Host "  - Exceptions detected (see above)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Full log saved in: $logFile" -ForegroundColor Cyan
    Write-Host "Please review the log file for more details" -ForegroundColor White
    Write-Host ""
}
