# Create User via Registration API
# This ensures password is hashed correctly by the backend

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Creating User via API" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

# Step 1: Delete existing user from database
Write-Host "[1/4] Deleting existing user from database..." -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$deleteSql = "DELETE FROM users WHERE email = '$email';"
psql -U postgres -d postgres -h localhost -p 5432 -c $deleteSql 2>$null
Remove-Item Env:\PGPASSWORD
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 2: Register user via API
Write-Host "[2/4] Registering user via API..." -ForegroundColor Yellow
$registerBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/register" `
        -Method Post `
        -Body $registerBody `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop

    Write-Host "  ✓ User registered successfully" -ForegroundColor Green
    Write-Host "  Response: $response" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Registration failed: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.ErrorDetails.Message) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Please check backend logs for errors" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 3: Update role to ADMIN in database
Write-Host "[3/4] Updating user role to ADMIN..." -ForegroundColor Yellow
$env:PGPASSWORD = "55662211@@@"
$updateSql = "UPDATE users SET role = 'ADMIN', kyc_status = 'APPROVED', credits = 1000.00 WHERE email = '$email';"
psql -U postgres -d postgres -h localhost -p 5432 -c $updateSql 2>$null
Remove-Item Env:\PGPASSWORD
Write-Host "  ✓ User updated to ADMIN" -ForegroundColor Green
Write-Host ""

# Step 4: Test login
Write-Host "[4/4] Testing login..." -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -TimeoutSec 5 `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  ✓✓✓ SUCCESS! ✓✓✓" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Login Successful!" -ForegroundColor Cyan
    Write-Host "  User ID: $($loginResponse.userId)" -ForegroundColor White
    Write-Host "  Email:   $($loginResponse.email)" -ForegroundColor White
    Write-Host "  Role:    $($loginResponse.role)" -ForegroundColor White
    Write-Host ""
    Write-Host "JWT Token:" -ForegroundColor Cyan
    Write-Host "  $($loginResponse.token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Login is working!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Credentials:" -ForegroundColor Yellow
    Write-Host "  Email:    $email" -ForegroundColor White
    Write-Host "  Password: $password" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  Login Still Failed" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow

    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Please check backend logs for authentication errors" -ForegroundColor Yellow
    exit 1
}
