# Direct Login Test
# Skips health check and directly tests login

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Direct Login Test" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

Write-Host "Testing login endpoint directly..." -ForegroundColor Yellow
Write-Host "  URL: $baseUrl/api/v1/auth/login" -ForegroundColor Gray
Write-Host "  Email: $email" -ForegroundColor Gray
Write-Host "  Password: $password" -ForegroundColor Gray
Write-Host ""

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

Write-Host "Sending login request..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  ✓ LOGIN SUCCESSFUL!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response Details:" -ForegroundColor Cyan
    Write-Host "  User ID:    $($response.userId)" -ForegroundColor White
    Write-Host "  Email:      $($response.email)" -ForegroundColor White
    Write-Host "  Role:       $($response.role)" -ForegroundColor White
    Write-Host "  Token Type: $($response.tokenType)" -ForegroundColor White
    Write-Host ""
    Write-Host "JWT Token:" -ForegroundColor Cyan
    Write-Host $response.token -ForegroundColor Gray
    Write-Host ""
    Write-Host "✓ Backend is working correctly!" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Login Request Failed" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""

    # Get error details
    $errorMessage = $_.Exception.Message
    Write-Host "Error: $errorMessage" -ForegroundColor Yellow
    Write-Host ""

    # Check for specific error types
    if ($errorMessage -match "unable to connect" -or $errorMessage -match "连接") {
        Write-Host "Diagnosis: Backend is NOT running or not accessible" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Cyan
        Write-Host "  1. Is the backend console window open and showing logs?" -ForegroundColor White
        Write-Host "  2. Did you see 'Started TruthProtocolApplication' message?" -ForegroundColor White
        Write-Host "  3. Check port 8080:" -ForegroundColor White
        Write-Host "     Get-NetTCPConnection -LocalPort 8080" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To start backend:" -ForegroundColor Cyan
        Write-Host "  .\cleanup-all-java.ps1" -ForegroundColor Gray
        Write-Host "  .\start-dev.ps1" -ForegroundColor Gray
        Write-Host ""

    } elseif ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "HTTP Status Code: $statusCode" -ForegroundColor Yellow

        if ($statusCode -eq 401) {
            Write-Host ""
            Write-Host "Diagnosis: Backend is running, but login failed (401 Unauthorized)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "This means:" -ForegroundColor Cyan
            Write-Host "  - Backend is working ✓" -ForegroundColor Green
            Write-Host "  - Login endpoint is accessible ✓" -ForegroundColor Green
            Write-Host "  - Credentials are incorrect ✗" -ForegroundColor Red
            Write-Host ""
            Write-Host "Fix the user:" -ForegroundColor Cyan
            Write-Host "  .\diagnose-login.ps1" -ForegroundColor Gray
            Write-Host ""

        } elseif ($statusCode -eq 404) {
            Write-Host ""
            Write-Host "Diagnosis: Backend is running, but login endpoint not found" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Possible issues:" -ForegroundColor Cyan
            Write-Host "  - Wrong URL path" -ForegroundColor White
            Write-Host "  - Backend not fully started" -ForegroundColor White
            Write-Host "  - Context path configured differently" -ForegroundColor White
            Write-Host ""

        } elseif ($statusCode -eq 500) {
            Write-Host ""
            Write-Host "Diagnosis: Backend error (500 Internal Server Error)" -ForegroundColor Yellow
            Write-Host ""
            if ($_.ErrorDetails.Message) {
                Write-Host "Server Response:" -ForegroundColor Cyan
                Write-Host $_.ErrorDetails.Message -ForegroundColor Gray
            }
            Write-Host ""
            Write-Host "Check backend console for error details" -ForegroundColor Cyan
            Write-Host ""
        }
    }

    Write-Host "For more diagnostics, run:" -ForegroundColor Cyan
    Write-Host "  .\detailed-check.ps1" -ForegroundColor White
    Write-Host ""
}
