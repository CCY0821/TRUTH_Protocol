# DEFINITIVE TEST - Using user-provided zero-balance account

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "TESTING MINT ENDPOINT WITH ZERO BALANCE ACCOUNT" -ForegroundColor Cyan
Write-Host "Email: AA@example.com | Balance: 0" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login
Write-Host "Step 1: Logging in..." -ForegroundColor Yellow

$loginBody = '{
  "email": "AA@example.com",
  "password": "password123"
}'

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $loginBody
    
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0, 30))..." -ForegroundColor Gray
    Write-Host ""
    
}
catch {
    Write-Host "❌ Login failed!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        Write-Host $errorBody -ForegroundColor Red
    }
    catch {}
    exit 1
}

# Step 2: Verify balance is 0
Write-Host "Step 2: Checking balance..." -ForegroundColor Yellow

try {
    $balanceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/credits/balance" `
        -Method GET `
        -Headers @{
        "Authorization" = "Bearer $token"
    }
    
    Write-Host "Current Balance: $($balanceResponse.balance)" -ForegroundColor White
    Write-Host ""
    
}
catch {
    Write-Host "⚠️ Could not check balance" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Test mint endpoint (should get 402 or 400)
Write-Host "Step 3: Testing mint endpoint with request body..." -ForegroundColor Yellow
Write-Host ""

$mintBody = '{
  "recipientWalletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
  "issuerRefId": "ZERO-BALANCE-TEST",
  "metadata": {
    "title": "Zero Balance Test",
    "description": "Testing with zero balance account"
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
    
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "✅ SUCCESS (unexpected - balance should be 0)" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host ($mintResponse | ConvertTo-Json -Depth 5) -ForegroundColor White
    
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "Status Code: $statusCode" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        Write-Host "Response Body:" -ForegroundColor White
        Write-Host $errorBody -ForegroundColor White
        Write-Host ""
        
        if ($errorBody -like "*Required request body is missing*") {
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host "❌ CONFIRMED: Backend code IS BROKEN" -ForegroundColor Red
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host "The request body is NOT being read by the controller." -ForegroundColor Red
            Write-Host "This is the SAME error as Swagger UI." -ForegroundColor Red
            Write-Host "Problem is in the backend code, not Swagger UI." -ForegroundColor Red
            
        }
        elseif ($statusCode -eq 402) {
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "✅ PERFECT: Got 402 Payment Required" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "This means:" -ForegroundColor Green
            Write-Host "1. Request body WAS successfully read ✅" -ForegroundColor Green
            Write-Host "2. Controller received the data ✅" -ForegroundColor Green
            Write-Host "3. Credits check worked correctly ✅" -ForegroundColor Green
            Write-Host "4. Backend code is WORKING PERFECTLY ✅" -ForegroundColor Green
            Write-Host "" -ForegroundColor Green
            Write-Host "CONCLUSION: Swagger UI has a bug, not the backend!" -ForegroundColor Green
            
        }
        else {
            Write-Host "Got status $statusCode - analyzing..." -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "Could not read error body" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
