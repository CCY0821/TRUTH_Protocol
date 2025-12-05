# Quick test for insufficient credits using curl
# This script uses the stored JWT token from login

$TOKEN_FILE = "jwt-token.txt"

if (-Not (Test-Path $TOKEN_FILE)) {
    Write-Host "❌ Token file not found. Testing with basic auth instead..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please provide your login credentials:" -ForegroundColor Cyan
    $email = Read-Host "Email"
    $password = Read-Host "Password" -AsSecureString
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    # Login first
    Write-Host "Logging in..." -ForegroundColor Yellow
    $loginBody = @{
        email    = $email
        password = $passwordPlain
    } | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" `
            -Method POST `
            -Headers @{"Content-Type" = "application/json" } `
            -Body $loginBody
        
        $JWT_TOKEN = $loginResponse.token
        Write-Host "✅ Login successful!" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "❌ Login failed!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
else {
    $JWT_TOKEN = (Get-Content $TOKEN_FILE -Raw).Trim()
}

# Now test mint endpoint
Write-Host "Testing POST /api/v1/credentials/mint with balance = 0" -ForegroundColor Cyan
Write-Host ""

$body = @'
{
  "recipientWalletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
  "issuerRefId": "TEST-INSUFFICIENT-001",
  "metadata": {
    "title": "Test Credential",
    "description": "Testing insufficient credits"
  }
}
'@

Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $body -ForegroundColor White
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/credentials/mint" `
        -Method POST `
        -Headers @{
        "Authorization" = "Bearer $JWT_TOKEN"
        "Content-Type"  = "application/json"
    } `
        -Body $body
    
    Write-Host "✅ Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
    
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    Write-Host "Status Code: $statusCode" -ForegroundColor Yellow
    
    if ($statusCode -eq 402) {
        Write-Host "✅ Expected: 402 Payment Required" -ForegroundColor Green
    }
    elseif ($statusCode -eq 400) {
        Write-Host "❌ Got: 400 Bad Request (unexpected)" -ForegroundColor Red
    }
    
    # Read error body
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        Write-Host ""
        Write-Host "Response Body:" -ForegroundColor White
        Write-Host $errorBody -ForegroundColor White
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
