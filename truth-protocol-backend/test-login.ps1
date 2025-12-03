# Test Login Script
# Tests the login functionality with the admin user

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Testing Login API" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

# Check if backend is running
Write-Host "Checking backend status..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Backend is NOT running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the backend first:" -ForegroundColor Yellow
    Write-Host "  cd truth-protocol-backend" -ForegroundColor White
    Write-Host "  .\start-dev.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Test login
Write-Host "Testing login with:" -ForegroundColor Yellow
Write-Host "  Email:    $email" -ForegroundColor White
Write-Host "  Password: $password" -ForegroundColor White
Write-Host ""

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

Write-Host "Sending login request..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "✓ LOGIN SUCCESSFUL!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response Details:" -ForegroundColor Cyan
    Write-Host "  User ID:    $($response.userId)" -ForegroundColor White
    Write-Host "  Email:      $($response.email)" -ForegroundColor White
    Write-Host "  Role:       $($response.role)" -ForegroundColor White
    Write-Host "  Token Type: $($response.tokenType)" -ForegroundColor White
    Write-Host ""
    Write-Host "JWT Token (first 80 chars):" -ForegroundColor Cyan
    $tokenPreview = $response.token.Substring(0, [Math]::Min(80, $response.token.Length))
    Write-Host "  $tokenPreview..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Full Token (for testing):" -ForegroundColor Cyan
    Write-Host $response.token -ForegroundColor Gray
    Write-Host ""
    Write-Host "You can use this token for authenticated requests:" -ForegroundColor Yellow
    Write-Host "  Authorization: Bearer <token>" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "✗ LOGIN FAILED!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""

    $statusCode = $_.Exception.Response.StatusCode.value__
    $statusDescription = $_.Exception.Response.StatusDescription

    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host "  Status Code: $statusCode $statusDescription" -ForegroundColor White

    if ($_.ErrorDetails.Message) {
        Write-Host "  Message: $($_.ErrorDetails.Message)" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Possible Issues:" -ForegroundColor Yellow

    if ($statusCode -eq 401) {
        Write-Host "  1. Password hash in database may be incorrect" -ForegroundColor White
        Write-Host "  2. Email or password is wrong" -ForegroundColor White
        Write-Host ""
        Write-Host "Try running: .\diagnose-login.ps1" -ForegroundColor Cyan
    } elseif ($statusCode -eq 404) {
        Write-Host "  1. Backend endpoint not found" -ForegroundColor White
        Write-Host "  2. Check backend is running correctly" -ForegroundColor White
    } else {
        Write-Host "  1. Check backend logs for errors" -ForegroundColor White
        Write-Host "  2. Verify database connection" -ForegroundColor White
    }

    Write-Host ""
    exit 1
}
