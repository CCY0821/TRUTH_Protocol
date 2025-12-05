# Test if mint endpoint actually works - DEFINITIVE TEST

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEFINITIVE API TEST" -ForegroundColor Cyan
Write-Host "Testing if backend code is broken or Swagger UI is broken" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login with admin user
Write-Host "Step 1: Logging in as admin..." -ForegroundColor Yellow

$loginBody = '{
  "email": "admin@truthprotocol.com",
  "password": "admin123"
}'

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $loginBody
    
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host ""
    
}
catch {
    Write-Host "❌ Login failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 2: Test mint endpoint with request body
Write-Host "Step 2: Calling mint endpoint with request body..." -ForegroundColor Yellow
Write-Host ""

$mintBody = '{
  "recipientWalletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
  "issuerRefId": "PROOF-TEST-001",
  "metadata": {
    "title": "Proof Test",
    "description": "This proves whether code is broken"
  }
}'

Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $mintBody -ForegroundColor White
Write-Host ""

try {
    $mintResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/credentials/mint" `
        -Method POST `
        -Headers @{
        "Authorization" = "Bearer $token"
    } `
        -ContentType "application/json" `
        -Body $mintBody
    
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "✅ SUCCESS! API returned 200/202" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor White
    Write-Host ($mintResponse | ConvertTo-Json -Depth 5) -ForegroundColor White
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "CONCLUSION: Backend code works PERFECTLY" -ForegroundColor Green
    Write-Host "The problema is 100% Swagger UI bug" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    Write-Host "Status Code: $statusCode" -ForegroundColor Yellow
    
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        Write-Host "Response Body:" -ForegroundColor White
        Write-Host $errorBody -ForegroundColor White
        Write-Host ""
        
        if ($statusCode -eq 400 -and $errorBody -like "*Required request body is missing*") {
            Write-Host "============================================" -ForegroundColor Red  
            Write-Host "❌ GOT SAME ERROR AS SWAGGER UI" -ForegroundColor Red
            Write-Host "Backend code IS BROKEN" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Red
            
        }
        elseif ($statusCode -eq 402) {
            Write-Host "============================================" -ForegroundColor Green
            Write-Host "✅ Got 402 Payment Required" -ForegroundColor Green
            Write-Host "This is CORRECT behavior (insufficient credits)" -ForegroundColor Green
            Write-Host "Backend code works PERFECTLY" -ForegroundColor Green
            Write-Host "Swagger UI has a bug" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            
        }
        else {
            Write-Host "Got different error - Status: $statusCode" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
