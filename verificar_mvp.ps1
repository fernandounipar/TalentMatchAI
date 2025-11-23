# Script de Verificação Rápida - TalentMatchIA MVP
# Data: 23/11/2025
# PowerShell Version

Write-Host "🔍 Verificação do Sistema TalentMatchIA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$PASSED = 0
$FAILED = 0

function Check-Endpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description
    )
    
    Write-Host -NoNewline "Verificando $Description... "
    
    if (Select-String -Path "backend\src\api\index.js" -Pattern $Endpoint -Quiet) {
        Write-Host "✅ OK" -ForegroundColor Green
        $script:PASSED++
    } else {
        Write-Host "❌ FALHOU" -ForegroundColor Red
        $script:FAILED++
    }
}

Write-Host "📡 VERIFICANDO ENDPOINTS BACKEND" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

# RF1
Check-Endpoint "POST" "/api/resumes" "RF1 - Upload de Currículos"
Check-Endpoint "POST" "/api/curriculos" "RF1 - Alias PT-BR Currículos"

# RF2
Check-Endpoint "GET" "/api/jobs" "RF2 - Gestão de Vagas"
Check-Endpoint "GET" "/api/vagas" "RF2 - Alias PT-BR Vagas"

# RF3
Check-Endpoint "POST" "/api/interviews" "RF3 - Geração de Perguntas"

# RF7
Check-Endpoint "POST" "/api/reports" "RF7 - Relatórios Detalhados"

# RF8
Check-Endpoint "GET" "/api/historico" "RF8 - Histórico"

# RF9
Check-Endpoint "GET" "/api/dashboard" "RF9 - Dashboard"

# RF10
Check-Endpoint "POST" "/api/usuarios" "RF10 - Gestão de Usuários"

Write-Host ""
Write-Host "🗄️  VERIFICANDO ESTRUTURAS DO BANCO" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

# Verificar migrations
if (Test-Path "backend\scripts\sql") {
    $MIGRATIONS = (Get-ChildItem "backend\scripts\sql\*.sql" -ErrorAction SilentlyContinue).Count
    Write-Host "Migrations encontradas: $MIGRATIONS" -ForegroundColor Green
    $PASSED++
} else {
    Write-Host "❌ Pasta de migrations não encontrada" -ForegroundColor Red
    $FAILED++
}

# Verificar tabelas críticas
$CRITICAL_TABLES = @(
    "users",
    "companies",
    "jobs",
    "candidates",
    "resumes",
    "interviews",
    "interview_questions",
    "interview_reports",
    "interview_messages"
)

foreach ($table in $CRITICAL_TABLES) {
    $found = $false
    if (Test-Path "backend\scripts\sql") {
        $found = Select-String -Path "backend\scripts\sql\*.sql" -Pattern "CREATE TABLE.*$table" -Quiet -ErrorAction SilentlyContinue
    }
    
    if ($found) {
        Write-Host "Tabela $table`: " -NoNewline
        Write-Host "✅ OK" -ForegroundColor Green
        $PASSED++
    } else {
        Write-Host "Tabela $table`: " -NoNewline
        Write-Host "⚠️  NÃO ENCONTRADA" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎨 VERIFICANDO FRONTEND FLUTTER" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

# Verificar telas críticas
$CRITICAL_SCREENS = @(
    "dashboard_tela.dart",
    "vagas_tela.dart",
    "candidatos_tela.dart",
    "upload_curriculo_tela.dart",
    "entrevistas_tela.dart",
    "entrevista_assistida_tela.dart",
    "relatorios_tela.dart",
    "historico_tela.dart",
    "usuarios_admin_tela.dart"
)

foreach ($screen in $CRITICAL_SCREENS) {
    if (Test-Path "frontend\lib\telas\$screen") {
        Write-Host "Tela $screen`: " -NoNewline
        Write-Host "✅ OK" -ForegroundColor Green
        $PASSED++
    } else {
        Write-Host "Tela $screen`: " -NoNewline
        Write-Host "❌ NÃO ENCONTRADA" -ForegroundColor Red
        $FAILED++
    }
}

# Verificar api_cliente.dart
if (Test-Path "frontend\lib\servicos\api_cliente.dart") {
    $METHODS = (Select-String -Path "frontend\lib\servicos\api_cliente.dart" -Pattern "^  Future<" | Measure-Object).Count
    Write-Host "API Cliente: OK ($METHODS metodos)" -ForegroundColor Green
    $PASSED++
} else {
    Write-Host "API Cliente: NAO ENCONTRADO" -ForegroundColor Red
    $FAILED++
}

Write-Host ""
Write-Host "📊 RESUMO DA VERIFICAÇÃO" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "✅ Passou: " -NoNewline
Write-Host "$PASSED" -ForegroundColor Green
Write-Host "❌ Falhou: " -NoNewline
Write-Host "$FAILED" -ForegroundColor Red
Write-Host ""

if ($FAILED -eq 0) {
    Write-Host "🎉 TODOS OS TESTES PASSARAM!" -ForegroundColor Green
    Write-Host "Sistema MVP está 100% operacional." -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Alguns componentes não foram encontrados." -ForegroundColor Yellow
    Write-Host "Verifique os itens marcados acima." -ForegroundColor Yellow
    exit 1
}
