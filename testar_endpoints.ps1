# Teste de Endpoints - TalentMatchIA MVP
# Execute: .\testar_endpoints.ps1

Write-Host "Testando Endpoints do Backend" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

$BASE_URL = "http://localhost:4000"

function Test-Endpoint {
    param([string]$Method, [string]$Path, [string]$Description)
    
    Write-Host -NoNewline "[$Method] $Path - "
    
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL$Path" -Method $Method -ErrorAction Stop
        Write-Host "OK (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "OK (Requires Auth: 401)" -ForegroundColor Yellow
            return $true
        } else {
            Write-Host "FAIL (Status: $statusCode)" -ForegroundColor Red
            return $false
        }
    }
}

Write-Host "TESTANDO ENDPOINTS MVP" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow
Write-Host ""

# Testar health check
Write-Host "Health Check:" -ForegroundColor Cyan
Test-Endpoint "GET" "/" "Root endpoint"
Write-Host ""

# RF7 - Relatórios
Write-Host "RF7 - Relatorios:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/reports" "Listar relatorios"
Write-Host ""

# RF3 - Perguntas (nested em interviews)
Write-Host "RF3 - Perguntas (via interviews):" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/interviews" "Listar entrevistas"
Write-Host ""

# RF1 - Currículos
Write-Host "RF1 - Curriculos:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/curriculos" "Listar curriculos"
Test-Endpoint "GET" "/api/resumes" "Listar curriculos (alias EN)"
Write-Host ""

# RF2 - Vagas
Write-Host "RF2 - Vagas:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/vagas" "Listar vagas"
Test-Endpoint "GET" "/api/jobs" "Listar vagas (alias EN)"
Write-Host ""

# RF8 - Histórico
Write-Host "RF8 - Historico:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/historico" "Listar historico"
Write-Host ""

# RF9 - Dashboard
Write-Host "RF9 - Dashboard:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/dashboard" "Dashboard stats"
Write-Host ""

# RF10 - Usuários
Write-Host "RF10 - Usuarios:" -ForegroundColor Cyan
Test-Endpoint "GET" "/api/usuarios" "Listar usuarios"
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Teste Completo!" -ForegroundColor Green
Write-Host ""
Write-Host "Nota: Status 401 (Unauthorized) eh esperado" -ForegroundColor Yellow
Write-Host "pois os endpoints exigem autenticacao." -ForegroundColor Yellow
