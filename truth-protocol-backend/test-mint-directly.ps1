# Test if mint endpoint actually works (bypassing Swagger UI)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Mint Endpoint Directly" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login
Write-Host "Step 1: Logging in..." -ForegroundColor Yellow

$loginBody = @{
    email    = "issuer@test.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $loginBody
    
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host ""
    
}
catch {
    Write-Host "❌ Login failed!" -ForegroundColor Red
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    $reader.Close()
    Write-Host $errorBody -ForegroundColor Red
    exit 1
}

# Step 2: Test mint endpoint
Write-Host "Step 2: Testing mint endpoint..." -ForegroundColor Yellow
Write-Host ""

$mintBody = @{
    recipientWalletAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0"
    issuerRefId            = "DIRECT-TEST-001"
    metadata               = @{
        title       = "Direct API Test"
        description = "Testing if API code actually works"
    }
} | ConvertTo-Json -Depth 5

Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $mintBody -ForegroundColor White
Write-Host ""

try {
    $mintResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/credentials/mint" `
        -Method POST `
        -Headers @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    } `
        -Body $mintBody
    
    Write-Host "✅ Mint request successful!" -ForegroundColor Green
    Write-Host ($mintResponse | ConvertTo-Json -Depth 5) -ForegroundColor White
    Write-Host ""
    Write-Host "✅ API CODE WORKS CORRECTLY - This proves Swagger UI has a bug." -ForegroundColor Green
    
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    Write-Host "Status Code: $statusCode" -ForegroundColor Yellow
    
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    $reader.Close()
    
    Write-Host "Response:" -ForegroundColor White
    Write-Host $errorBody -ForegroundColor White
    Write-Host ""
    
    if ($statusCode -eq 402) {
        Write-Host "✅ Got 402 Payment Required - this is CORRECT behavior!" -ForegroundColor Green
        Write-Host "✅ API CODE WORKS CORRECTLY - This proves Swagger UI has a bug." -ForegroundColor Green
    }
    elseif ($statusCode -eq 400 -and $errorBody -like "*Required request body is missing*") {
        Write-Host "❌ Got the same error - API CODE HAS A BUG" -ForegroundColor Red
        Write-Host "The problem is in the backend code, not Swagger UI." -ForegroundColor Red
    }
    else {
        Write-Host "Got unexpected error - need to investigate" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
