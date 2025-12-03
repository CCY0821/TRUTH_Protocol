# Test PostgreSQL Connection Script
# Tests connection to local PostgreSQL database

Write-Host "Testing PostgreSQL Connection..." -ForegroundColor Cyan
Write-Host "Database: postgres" -ForegroundColor Yellow
Write-Host "Host: localhost:5432" -ForegroundColor Yellow
Write-Host "User: postgres" -ForegroundColor Yellow
Write-Host ""

$env:PGPASSWORD = "55662211@@@"

try {
    $result = psql -U postgres -d postgres -h localhost -p 5432 -c "SELECT 'Connection successful!' as status, version();" -t 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database connection successful!" -ForegroundColor Green
        Write-Host $result
    } else {
        Write-Host "✗ Database connection failed!" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} catch {
    Write-Host "✗ Error testing database connection: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item Env:\PGPASSWORD
}
