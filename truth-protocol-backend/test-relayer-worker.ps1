# Relayer Worker E2E Test Script
# Tests the complete async credential issuance flow

Write-Host "========================================"
Write-Host "Relayer Worker End-to-End Test"
Write-Host "========================================"
Write-Host ""

$baseUrl = "http://localhost:8080"
$email = "issuer@example.com"
$password = "password123"

# Step 1: Login
Write-Host "[Step 1] Login to get JWT token..." -ForegroundColor Yellow

$loginBody = @{
    email    = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/auth/login" `
        -Method POST `
        -Body $loginBody `
        -ContentType "application/json"
    
    $token = $loginResponse.token
    Write-Host "Success: Logged in" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "Error: Login failed - $_" -ForegroundColor Red
    exit 1
}

# Step 2: Check balance
Write-Host "[Step 2] Check credit balance..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $balance = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/credits/balance" `
        -Method GET `
        -Headers $headers
    
    Write-Host "Success: Current balance = $($balance.balance)" -ForegroundColor Green
    
    if ($balance.balance -lt 1) {
        Write-Host "Warning: Insufficient balance" -ForegroundColor Yellow
        Write-Host "Run: .\purchase-credits.ps1 to add credits" -ForegroundColor Yellow
        exit 1
    }
    Write-Host ""
}
catch {
    Write-Host "Error: Failed to get balance - $_" -ForegroundColor Red
    exit 1
}

# Step 3: Mint credential (should return QUEUED)
Write-Host "[Step 3] Mint credential..." -ForegroundColor Yellow

$mintBody = @{
    recipientWalletAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0"
    issuerRefId            = "TEST-RELAYER-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    metadata               = @{
        title       = "Relayer Worker Test Credential"
        description = "Testing async processing flow"
        attributes  = @(
            @{
                trait_type = "Test Type"
                value      = "Relayer E2E Test"
            },
            @{
                trait_type = "Timestamp"
                value      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $mintResponse = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/credentials/mint" `
        -Method POST `
        -Headers $headers `
        -Body $mintBody `
        -ContentType "application/json"
    
    $credentialId = $mintResponse.jobId  # FIXED: Use jobId instead of id
    $initialStatus = $mintResponse.status
    
    Write-Host "Success: Credential created" -ForegroundColor Green
    Write-Host "  Job ID: $credentialId" -ForegroundColor Gray
    Write-Host "  Initial Status: $initialStatus" -ForegroundColor Gray
    
    if ($initialStatus -ne "QUEUED") {
        Write-Host "Warning: Expected status QUEUED, got: $initialStatus" -ForegroundColor Yellow
    }
    Write-Host ""
}
catch {
    Write-Host "Error: Minting failed - $_" -ForegroundColor Red
    exit 1
}

# Step 4: Poll for status change
Write-Host "[Step 4] Waiting for Relayer Worker to process..." -ForegroundColor Yellow
Write-Host "Relayer scans every 5 seconds for QUEUED credentials" -ForegroundColor Gray
Write-Host ""

$maxPolls = 24  # Max 2 minutes
$pollCount = 0
$confirmed = $false

while ($pollCount -lt $maxPolls -and -not $confirmed) {
    Start-Sleep -Seconds 5
    $pollCount++
    
    Write-Host "  [Poll $pollCount] Checking status..." -ForegroundColor Cyan
    
    try {
        $credential = Invoke-RestMethod `
            -Uri "$baseUrl/api/v1/credentials/$credentialId" `
            -Method GET `
            -Headers $headers
        
        $currentStatus = $credential.status
        $arweaveHash = $credential.arweaveHash
        $tokenId = $credential.tokenId
        
        Write-Host "    Status: $currentStatus" -ForegroundColor Gray
        
        if ($arweaveHash) {
            Write-Host "    Arweave Hash: $arweaveHash" -ForegroundColor Gray
        }
        
        if ($tokenId) {
            Write-Host "    Token ID: $tokenId" -ForegroundColor Gray
        }
        
        if ($currentStatus -eq "CONFIRMED") {
            $confirmed = $true
            Write-Host ""
            Write-Host "Success: Credential CONFIRMED!" -ForegroundColor Green
            break
        }
        
        if ($currentStatus -eq "FAILED") {
            Write-Host ""
            Write-Host "Error: Processing FAILED" -ForegroundColor Red
            break
        }
        
    }
    catch {
        Write-Host "    Query failed: $_" -ForegroundColor Red
    }
}

if (-not $confirmed) {
    Write-Host ""
    Write-Host "Timeout: No confirmation after $($maxPolls * 5) seconds" -ForegroundColor Yellow
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Relayer Worker not running" -ForegroundColor Gray
    Write-Host "  2. Scheduling not enabled" -ForegroundColor Gray
    Write-Host "  3. Processing error occurred" -ForegroundColor Gray
    exit 1
}

# Step 5: Verify final result
Write-Host ""
Write-Host "[Step 5] Verify final result..." -ForegroundColor Yellow

try {
    $finalCredential = Invoke-RestMethod `
        -Uri "$baseUrl/api/v1/credentials/$credentialId" `
        -Method GET `
        -Headers $headers
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Final Credential Info"
    Write-Host "========================================"
    Write-Host "ID: $($finalCredential.id)"
    Write-Host "Status: $($finalCredential.status)" -ForegroundColor Green
    Write-Host "Arweave Hash: $($finalCredential.arweaveHash)"
    Write-Host "Token ID: $($finalCredential.tokenId)"
    Write-Host "Created At: $($finalCredential.createdAt)"
    Write-Host ""
    
    # Verify all fields
    $allFieldsPresent = $true
    
    if (-not $finalCredential.arweaveHash) {
        Write-Host "Missing: Arweave Hash" -ForegroundColor Red
        $allFieldsPresent = $false
    }
    else {
        Write-Host "OK: Arweave Hash is set" -ForegroundColor Green
    }
    
    if (-not $finalCredential.tokenId) {
        Write-Host "Missing: Token ID" -ForegroundColor Red
        $allFieldsPresent = $false
    }
    else {
        Write-Host "OK: Token ID is set" -ForegroundColor Green
    }
    
    if ($finalCredential.status -ne "CONFIRMED") {
        Write-Host "Wrong: Status is not CONFIRMED" -ForegroundColor Red
        $allFieldsPresent = $false
    }
    else {
        Write-Host "OK: Status is CONFIRMED" -ForegroundColor Green
    }
    
    Write-Host ""
    
    if ($allFieldsPresent) {
        Write-Host "========================================"  -ForegroundColor Green
        Write-Host "TEST PASSED! Relayer Worker is working" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    }
    else {
        Write-Host "========================================"  -ForegroundColor Red
        Write-Host "TEST FAILED: Some fields are missing" -ForegroundColor Red
        Write-Host "========================================"  -ForegroundColor Red
        exit 1
    }
    
}
catch {
    Write-Host "Error: Verification failed - $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
