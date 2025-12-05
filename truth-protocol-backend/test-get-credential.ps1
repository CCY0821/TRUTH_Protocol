# Test GET credential endpoint directly

$baseUrl = "http://localhost:8080"
$email = "issuer@example.com"
$password = "password123"

# Login
$loginBody = @{ email = $email; password = $password } | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.token
$headers = @{ "Authorization" = "Bearer $token" }

# Get list of all credentials
Write-Host "Getting all credentials..." -ForegroundColor Yellow
try {
    $allCredentials = Invoke-RestMethod -Uri "$baseUrl/api/v1/credentials" -Method GET -Headers $headers
    Write-Host "Success: Found $($allCredentials.Count) credentials" -ForegroundColor Green
    
    if ($allCredentials.Count -gt 0) {
        $firstCred = $allCredentials[0]
        Write-Host ""
        Write-Host "First credential:" -ForegroundColor Cyan
        $firstCred | ConvertTo-Json -Depth 5 | Write-Host
        
        $credId = $firstCred.id
        Write-Host ""
        Write-Host "Now trying to get credential by ID: $credId" -ForegroundColor Yellow
        
        try {
            $singleCred = Invoke-RestMethod -Uri "$baseUrl/api/v1/credentials/$credId" -Method GET -Headers $headers
            Write-Host "Success!" -ForegroundColor Green
            $singleCred | ConvertTo-Json -Depth 5 | Write-Host
        }
        catch {
            Write-Host "Error getting single credential:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
