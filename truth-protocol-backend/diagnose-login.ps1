# Diagnose Login Issue
# Checks the password hash in database and provides fix

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Login Issue Diagnosis" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$email = "admin@truthprotocol.com"
$env:PGPASSWORD = "55662211@@@"

Write-Host "Step 1: Checking user in database..." -ForegroundColor Yellow
$checkUserSql = "SELECT email, role, LEFT(password_hash, 20) as hash_preview, LENGTH(password_hash) as hash_length FROM users WHERE email = '$email';"
psql -U postgres -d postgres -h localhost -p 5432 -c $checkUserSql

Write-Host ""
Write-Host "Step 2: Deleting existing user (if exists)..." -ForegroundColor Yellow
$deleteSql = "DELETE FROM users WHERE email = '$email';"
psql -U postgres -d postgres -h localhost -p 5432 -c $deleteSql

Write-Host ""
Write-Host "Step 3: Inserting new user with correct BCrypt hash..." -ForegroundColor Yellow
Write-Host "Note: BCrypt hash for 'admin123' generated using BCryptPasswordEncoder(10)" -ForegroundColor Gray

# This is a known-good BCrypt hash for "admin123" using strength 10
# Generated using: new BCryptPasswordEncoder(10).encode("admin123")
$correctHash = "`$2a`$10`$N9qo8uLOickgx2ZMRZoMye/IY/lGhzzN7mIQGLJ9.OrVLWyJkzJVy"

$insertSql = "INSERT INTO users (email, password_hash, role, kyc_status, credits) VALUES ('$email', '$correctHash', 'ADMIN', 'APPROVED', 1000.00);"
psql -U postgres -d postgres -h localhost -p 5432 -c $insertSql

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ User created successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create user" -ForegroundColor Red
    Remove-Item Env:\PGPASSWORD
    exit 1
}

Write-Host ""
Write-Host "Step 4: Verifying user creation..." -ForegroundColor Yellow
$verifySql = "SELECT id, email, role, kyc_status, credits, LEFT(password_hash, 30) as hash_preview FROM users WHERE email = '$email';"
psql -U postgres -d postgres -h localhost -p 5432 -c $verifySql

Remove-Item Env:\PGPASSWORD

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Diagnosis Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Make sure your backend is running:" -ForegroundColor White
Write-Host "   cd truth-protocol-backend" -ForegroundColor Gray
Write-Host "   .\start-dev.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test login with:" -ForegroundColor White
Write-Host "   Email:    $email" -ForegroundColor Gray
Write-Host "   Password: admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If login still fails, check backend logs" -ForegroundColor White
Write-Host ""
