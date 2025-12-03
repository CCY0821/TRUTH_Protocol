# Start Spring Boot Application with Dev Profile
# This script sets environment variables and starts the backend service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TRUTH Protocol Backend Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment: Development" -ForegroundColor Yellow
Write-Host "Profile: dev" -ForegroundColor Yellow
Write-Host "Database: PostgreSQL @ localhost:5432/postgres" -ForegroundColor Yellow
Write-Host ""

# Set environment variables
$env:SPRING_PROFILES_ACTIVE = "dev"
$env:DB_PASSWORD = "55662211@@@"
# Valid Base64 encoded secret (32 bytes / 256 bits minimum for HS256)
# Original: YourSuperSecretKeyForDevelopmentOnlyNotForProduction123456789
# Base64: WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ==
$env:JWT_SECRET = "WW91clN1cGVyU2VjcmV0S2V5Rm9yRGV2ZWxvcG1lbnRPbmx5Tm90Rm9yUHJvZHVjdGlvbjEyMzQ1Njc4OQ=="
$env:POLYGON_RPC_URL = "https://polygon-rpc.com"
$env:POLYGON_CHAIN_ID = "80001"

Write-Host "Starting application..." -ForegroundColor Green
Write-Host ""

# Run bootRun with Gradle
.\gradlew.bat bootRun --console=plain --info
