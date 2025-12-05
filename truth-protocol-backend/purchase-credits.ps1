# Quick script to purchase credits

$baseUrl = "http://localhost:8080"
$email = "issuer@example.com"
$password = "password123"

Write-Host "Purchasing credits..." -ForegroundColor Yellow

# Login
$loginBody = @{
    email    = $email
    password = $password
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod `
    -Uri "$baseUrl/api/v1/auth/login" `
    -Method POST `
    -Body $loginBody `
    -ContentType "application/json"

$token = $loginResponse.token

# Purchase 10 credits
$headers = @{
    "Authorization" = "Bearer $token"
}

$purchaseBody = @{
    amount           = 10
    paymentReference = "TEST-PURCHASE-" + (Get-Date -Format "yyyyMMddHHmmss")
} | ConvertTo-Json

try {
    $purchaseResponse = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/credits/purchase" `
        -Method POST `
        -Headers $headers `
        -Body $purchaseBody `
        -ContentType "application/json"
    
    Write-Host "Success! Purchased 10 credits" -ForegroundColor Green
    Write-Host "New balance: $($purchaseResponse.balance)" -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
