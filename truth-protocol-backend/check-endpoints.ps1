# Check Available Endpoints
# Tests various endpoints to see what's responding

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Checking Backend Endpoints" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$endpoints = @(
    @{Path="/"; Name="Root"},
    @{Path="/actuator"; Name="Actuator Root"},
    @{Path="/actuator/health"; Name="Health Check"},
    @{Path="/api/v1/auth/login"; Name="Login Endpoint"},
    @{Path="/swagger-ui.html"; Name="Swagger UI"},
    @{Path="/v3/api-docs"; Name="OpenAPI Docs"}
)

foreach ($endpoint in $endpoints) {
    $url = "$baseUrl$($endpoint.Path)"
    Write-Host "Testing: $($endpoint.Name)" -ForegroundColor Yellow
    Write-Host "  URL: $url" -ForegroundColor Gray

    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop
        Write-Host "  Status: $($response.StatusCode) " -ForegroundColor Green -NoNewline
        Write-Host "OK" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            if ($statusCode -eq 404) {
                Write-Host "  Status: 404 " -ForegroundColor Red -NoNewline
                Write-Host "NOT FOUND" -ForegroundColor Red
            } elseif ($statusCode -eq 401) {
                Write-Host "  Status: 401 " -ForegroundColor Yellow -NoNewline
                Write-Host "UNAUTHORIZED (endpoint exists)" -ForegroundColor Yellow
            } elseif ($statusCode -eq 405) {
                Write-Host "  Status: 405 " -ForegroundColor Yellow -NoNewline
                Write-Host "METHOD NOT ALLOWED (endpoint exists)" -ForegroundColor Yellow
            } else {
                Write-Host "  Status: $statusCode" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Error: " -ForegroundColor Red -NoNewline
            Write-Host "Cannot connect" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if any endpoint responded
try {
    $rootTest = Invoke-WebRequest -Uri "$baseUrl/" -Method Get -TimeoutSec 2 -ErrorAction Stop
    Write-Host "Backend is responding on port 8080" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode) {
        Write-Host "Backend is responding (HTTP $statusCode)" -ForegroundColor Yellow
    } else {
        Write-Host "Backend is NOT responding" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Cyan
        Write-Host "  1. Is the backend console window showing logs?" -ForegroundColor White
        Write-Host "  2. Did you see 'Started TruthProtocolApplication'?" -ForegroundColor White
        Write-Host ""
        exit 1
    }
}

Write-Host ""
Write-Host "If all endpoints return 404, the backend may be:" -ForegroundColor Yellow
Write-Host "  - Still starting up (wait 30-60 seconds)" -ForegroundColor White
Write-Host "  - Failed to start (check console for errors)" -ForegroundColor White
Write-Host ""
