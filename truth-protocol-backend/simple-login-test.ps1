# Simple Login Test - No fancy error handling

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Testing Login" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URL: $baseUrl/api/v1/auth/login" -ForegroundColor Gray
Write-Host "Email: $email" -ForegroundColor Gray
Write-Host "Password: $password" -ForegroundColor Gray
Write-Host ""

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

Write-Host "Sending request..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -TimeoutSec 5

    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "User ID: $($response.userId)" -ForegroundColor Cyan
    Write-Host "Email: $($response.email)" -ForegroundColor Cyan
    Write-Host "Role: $($response.role)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Token:" -ForegroundColor Cyan
    Write-Host $response.token -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "FAILED!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor White
    Write-Host ""

    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "HTTP Status: $statusCode" -ForegroundColor Yellow

        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor White
        }
    }
    Write-Host ""
}
