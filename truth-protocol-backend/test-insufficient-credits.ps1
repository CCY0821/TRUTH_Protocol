# ========================================================================
# Test Insufficient Credits (402 Payment Required)
# ========================================================================
# This script tests the insufficient credits scenario by calling
# POST /api/v1/credentials/mint with a valid request when balance is 0
# ========================================================================

# Configuration
$BASE_URL = "http://localhost:8080"
$TOKEN_FILE = "jwt-token.txt"

# Check if token file exists
if (-Not (Test-Path $TOKEN_FILE)) {
    Write-Host "❌ Error: JWT token file not found: $TOKEN_FILE" -ForegroundColor Red
    Write-Host "Please run login script first to generate JWT token" -ForegroundColor Yellow
    exit 1
}

# Read JWT token
$JWT_TOKEN = Get-Content $TOKEN_FILE -Raw
$JWT_TOKEN = $JWT_TOKEN.Trim()

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "Testing Insufficient Credits (POST /api/v1/credentials/mint)" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current balance
Write-Host "Step 1: Checking current credit balance..." -ForegroundColor Yellow
Write-Host "GET $BASE_URL/api/v1/credits/balance" -ForegroundColor Gray
Write-Host ""

try {
    $balanceResponse = Invoke-RestMethod -Uri "$BASE_URL/api/v1/credits/balance" `
        -Method GET `
        -Headers @{
        "Authorization" = "Bearer $JWT_TOKEN"
        "Content-Type"  = "application/json"
    }
    
    Write-Host "✅ Current Balance:" -ForegroundColor Green
    Write-Host ($balanceResponse | ConvertTo-Json -Depth 10) -ForegroundColor White
    Write-Host ""
    
    $currentBalance = [decimal]$balanceResponse.balance
    
    if ($currentBalance -gt 0) {
        Write-Host "⚠️  Warning: You still have $currentBalance credits" -ForegroundColor Yellow
        Write-Host "   To test insufficient credits, you need balance = 0.00" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Continue anyway? (The test might not show 402 error)" -ForegroundColor Yellow
        Write-Host "   Press Enter to continue or Ctrl+C to cancel..."
        Read-Host
    }
    
}
catch {
    Write-Host "❌ Failed to check balance" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 2: Try to mint credential (should fail with 402 if balance is 0)
Write-Host "Step 2: Attempting to mint credential..." -ForegroundColor Yellow
Write-Host "POST $BASE_URL/api/v1/credentials/mint" -ForegroundColor Gray
Write-Host ""

$mintRequest = @{
    recipientWalletAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0"
    issuerRefId            = "TEST-INSUFFICIENT-001"
    metadata               = @{
        title       = "Test Credential"
        description = "Testing insufficient credits scenario"
    }
} | ConvertTo-Json -Depth 10

Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $mintRequest -ForegroundColor White
Write-Host ""

try {
    $mintResponse = Invoke-RestMethod -Uri "$BASE_URL/api/v1/credentials/mint" `
        -Method POST `
        -Headers @{
        "Authorization" = "Bearer $JWT_TOKEN"
        "Content-Type"  = "application/json"
    } `
        -Body $mintRequest
    
    Write-Host "✅ Success (This shouldn't happen if balance is 0):" -ForegroundColor Green
    Write-Host ($mintResponse | ConvertTo-Json -Depth 10) -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Note: If balance was 0, this should have returned 402 Payment Required" -ForegroundColor Yellow
    
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    if ($statusCode -eq 402) {
        Write-Host "✅ Expected Error: 402 Payment Required" -ForegroundColor Green
        
        # Try to read error response
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        Write-Host "Error Response:" -ForegroundColor White
        Write-Host $errorBody -ForegroundColor White
        Write-Host ""
        Write-Host "✅ Test PASSED: Insufficient credits error works correctly!" -ForegroundColor Green
        
    }
    elseif ($statusCode -eq 400) {
        Write-Host "❌ Unexpected Error: 400 Bad Request" -ForegroundColor Red
        
        # Try to read error response
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
        
        Write-Host "Error Response:" -ForegroundColor White
        Write-Host $errorBody -ForegroundColor White
        Write-Host ""
        Write-Host "This might be a Swagger UI issue. The PowerShell request should work." -ForegroundColor Yellow
        
    }
    else {
        Write-Host "❌ Unexpected Error: $statusCode" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
