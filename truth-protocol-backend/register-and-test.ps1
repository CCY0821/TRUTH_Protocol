# Register User and Test Login

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

Write-Host "Step 1: Delete existing user" -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
psql -U postgres -d postgres -h localhost -p 5432 -c "DELETE FROM users WHERE email = '$email';" 2>$null
Remove-Item Env:\PGPASSWORD
Write-Host "Done" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Register via API" -ForegroundColor Yellow
$registerBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "SUCCESS: User registered" -ForegroundColor Green
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Step 3: Update to ADMIN" -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
psql -U postgres -d postgres -h localhost -p 5432 -c "UPDATE users SET role = 'ADMIN', kyc_status = 'APPROVED', credits = 1000.00 WHERE email = '$email';" 2>$null
Remove-Item Env:\PGPASSWORD
Write-Host "Done" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Test login" -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "User ID: $($loginResponse.userId)" -ForegroundColor Cyan
    Write-Host "Email: $($loginResponse.email)" -ForegroundColor Cyan
    Write-Host "Role: $($loginResponse.role)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Token: $($loginResponse.token.Substring(0,50))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}
