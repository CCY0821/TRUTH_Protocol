# Create Test User via Registration API
# This ensures the password is properly hashed by the backend

$baseUrl = "http://localhost:8080"
$email = "admin@truthprotocol.com"
$password = "admin123"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Creating Test User via Registration API" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Register the user
Write-Host "Step 1: Registering user..." -ForegroundColor Yellow
$registerBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/register" `
        -Method Post `
        -Body $registerBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host "✓ User registered successfully!" -ForegroundColor Green
    Write-Host $response
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "! User already exists, skipping registration" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 2: Update user role to ADMIN and add credits directly in database
Write-Host "Step 2: Updating user role and credits in database..." -ForegroundColor Yellow

$env:PGPASSWORD = "55662211@@@"
$updateSql = "UPDATE users SET role = 'ADMIN', kyc_status = 'APPROVED', credits = 1000.00 WHERE email = '$email';"

psql -U postgres -d postgres -h localhost -p 5432 -c $updateSql

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ User updated to ADMIN with 1000 credits!" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to update user role" -ForegroundColor Red
    Remove-Item Env:\PGPASSWORD
    exit 1
}

Remove-Item Env:\PGPASSWORD

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Test User Created Successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "Login Credentials:" -ForegroundColor Cyan
Write-Host "  Email:    $email" -ForegroundColor White
Write-Host "  Password: $password" -ForegroundColor White
Write-Host "  Role:     ADMIN" -ForegroundColor White
Write-Host "  Credits:  1000.00" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Step 3: Test login
Write-Host "Step 3: Testing login..." -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -ErrorAction Stop

    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "User ID: $($loginResponse.userId)" -ForegroundColor Gray
    Write-Host "Role: $($loginResponse.role)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
