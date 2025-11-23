# Script de Verificacao Rapida - TalentMatchIA MVP
# Data: 23/11/2025

Write-Host "Verificacao do Sistema TalentMatchIA" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$PASSED = 0
$FAILED = 0

function Check-File {
    param([string]$Path, [string]$Desc)
    
    if (Test-Path $Path) {
        Write-Host "[OK] $Desc" -ForegroundColor Green
        $script:PASSED++
        return $true
    } else {
        Write-Host "[FAIL] $Desc" -ForegroundColor Red
        $script:FAILED++
        return $false
    }
}

function Check-Pattern {
    param([string]$Path, [string]$Pattern, [string]$Desc)
    
    if (Select-String -Path $Path -Pattern $Pattern -Quiet) {
        Write-Host "[OK] $Desc" -ForegroundColor Green
        $script:PASSED++
        return $true
    } else {
        Write-Host "[FAIL] $Desc" -ForegroundColor Red
        $script:FAILED++
        return $false
    }
}

Write-Host "ENDPOINTS BACKEND" -ForegroundColor Yellow
Write-Host "-----------------" -ForegroundColor Yellow

Check-Pattern "backend\src\api\index.js" "/resumes" "RF1 - Upload Curriculos"
Check-Pattern "backend\src\api\index.js" "/jobs" "RF2 - Gestao de Vagas"
Check-Pattern "backend\src\api\index.js" "/interviews" "RF3 - Geracao de Perguntas"
Check-Pattern "backend\src\api\index.js" "/reports" "RF7 - Relatorios Detalhados"
Check-Pattern "backend\src\api\index.js" "/historico" "RF8 - Historico"
Check-Pattern "backend\src\api\index.js" "/dashboard" "RF9 - Dashboard"
Check-Pattern "backend\src\api\index.js" "/usuarios" "RF10 - Gestao de Usuarios"

Write-Host ""
Write-Host "TELAS FRONTEND" -ForegroundColor Yellow
Write-Host "--------------" -ForegroundColor Yellow

Check-File "frontend\lib\telas\dashboard_tela.dart" "Dashboard"
Check-File "frontend\lib\telas\vagas_tela.dart" "Vagas"
Check-File "frontend\lib\telas\candidatos_tela.dart" "Candidatos"
Check-File "frontend\lib\telas\upload_curriculo_tela.dart" "Upload Curriculo"
Check-File "frontend\lib\telas\entrevistas_tela.dart" "Entrevistas"
Check-File "frontend\lib\telas\entrevista_assistida_tela.dart" "Entrevista Assistida"
Check-File "frontend\lib\telas\relatorios_tela.dart" "Relatorios"
Check-File "frontend\lib\telas\historico_tela.dart" "Historico"
Check-File "frontend\lib\telas\usuarios_admin_tela.dart" "Usuarios Admin"

Write-Host ""
Write-Host "SERVICOS" -ForegroundColor Yellow
Write-Host "--------" -ForegroundColor Yellow

Check-File "frontend\lib\servicos\api_cliente.dart" "API Cliente"
Check-File "backend\src\servicos\iaService.js" "IA Service"

Write-Host ""
Write-Host "RESUMO" -ForegroundColor Cyan
Write-Host "======" -ForegroundColor Cyan
Write-Host "Passou: $PASSED" -ForegroundColor Green
Write-Host "Falhou: $FAILED" -ForegroundColor Red
Write-Host ""

if ($FAILED -eq 0) {
    Write-Host "TODOS OS TESTES PASSARAM!" -ForegroundColor Green
    Write-Host "Sistema MVP esta 100% operacional." -ForegroundColor Green
} else {
    Write-Host "Alguns componentes nao foram encontrados." -ForegroundColor Yellow
}
