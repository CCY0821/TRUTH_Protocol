# Debug version - shows full response

$baseUrl = "http://localhost:8080"
$email = "issuer@example.com"
$password = "password123"

Write-Host "========================================"
Write-Host "DEBUG: Mint and check response"
Write-Host "========================================"
Write-Host ""

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
$headers = @{
    "Authorization" = "Bearer $token"
}

Write-Host "Logged in successfully" -ForegroundColor Green
Write-Host ""

# Mint credential
Write-Host "Minting credential..." -ForegroundColor Yellow

$mintBody = @{
    recipientWalletAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0"
    issuerRefId            = "DEBUG-TEST-" + (Get-Date -Format "yyyyMMddHHmmss")
    metadata               = @{
        title       = "Debug Test"
        description = "Testing response structure"
    }
} | ConvertTo-Json -Depth 10

Write-Host "Request body:" -ForegroundColor Gray
Write-Host $mintBody -ForegroundColor Gray
Write-Host ""

try {
    $mintResponse = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/credentials/mint" `
        -Method POST `
        -Headers $headers `
        -Body $mintBody `
        -ContentType "application/json"
    
    Write-Host "SUCCESS: Credential created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Full Response:" -ForegroundColor Cyan
    $mintResponse | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
    Write-Host ""
    
    # Try different property names
    Write-Host "Checking properties:" -ForegroundColor Yellow
    Write-Host "  mintResponse.id = '$($mintResponse.id)'"
    Write-Host "  mintResponse.credentialId = '$($mintResponse.credentialId)'"
    Write-Host "  mintResponse.status = '$($mintResponse.status)'"
    
    # List all properties
    Write-Host ""
    Write-Host "All properties:"
    $mintResponse.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name) = $($_.Value)"
    }
    
}
catch {
    Write-Host "ERROR: Minting failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    Write-Host $_.Exception.Response -ForegroundColor Gray
}
