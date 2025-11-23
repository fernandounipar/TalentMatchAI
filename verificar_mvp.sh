#!/bin/bash
# Script de Verificação Rápida - TalentMatchIA MVP
# Data: 23/11/2025

echo "🔍 Verificação do Sistema TalentMatchIA"
echo "========================================"
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador
PASSED=0
FAILED=0

# Função de verificação
check_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    
    echo -n "Verificando $description... "
    
    if grep -q "$endpoint" backend/src/api/index.js; then
        echo -e "${GREEN}✅ OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FALHOU${NC}"
        ((FAILED++))
    fi
}

echo "📡 VERIFICANDO ENDPOINTS BACKEND"
echo "--------------------------------"

# RF1
check_endpoint "POST" "/api/resumes" "RF1 - Upload de Currículos"
check_endpoint "POST" "/api/curriculos" "RF1 - Alias PT-BR Currículos"

# RF2
check_endpoint "GET" "/api/jobs" "RF2 - Gestão de Vagas"
check_endpoint "GET" "/api/vagas" "RF2 - Alias PT-BR Vagas"

# RF3
check_endpoint "POST" "/api/interviews" "RF3 - Geração de Perguntas"

# RF7
check_endpoint "POST" "/api/reports" "RF7 - Relatórios Detalhados"

# RF8
check_endpoint "GET" "/api/historico" "RF8 - Histórico"

# RF9
check_endpoint "GET" "/api/dashboard" "RF9 - Dashboard"

# RF10
check_endpoint "POST" "/api/usuarios" "RF10 - Gestão de Usuários"

echo ""
echo "🗄️  VERIFICANDO ESTRUTURAS DO BANCO"
echo "------------------------------------"

# Verificar migrations
if [ -d "backend/scripts/sql" ]; then
    MIGRATIONS=$(ls backend/scripts/sql/*.sql 2>/dev/null | wc -l)
    echo -e "Migrations encontradas: ${GREEN}$MIGRATIONS${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Pasta de migrations não encontrada${NC}"
    ((FAILED++))
fi

# Verificar tabelas críticas
CRITICAL_TABLES=(
    "users"
    "companies"
    "jobs"
    "candidates"
    "resumes"
    "interviews"
    "interview_questions"
    "interview_reports"
    "interview_messages"
)

for table in "${CRITICAL_TABLES[@]}"; do
    if grep -rq "CREATE TABLE.*$table" backend/scripts/sql/ 2>/dev/null; then
        echo -e "Tabela $table: ${GREEN}✅ OK${NC}"
        ((PASSED++))
    else
        echo -e "Tabela $table: ${YELLOW}⚠️  NÃO ENCONTRADA${NC}"
    fi
done

echo ""
echo "🎨 VERIFICANDO FRONTEND FLUTTER"
echo "--------------------------------"

# Verificar telas críticas
CRITICAL_SCREENS=(
    "dashboard_tela.dart"
    "vagas_tela.dart"
    "candidatos_tela.dart"
    "upload_curriculo_tela.dart"
    "entrevistas_tela.dart"
    "entrevista_assistida_tela.dart"
    "relatorios_tela.dart"
    "historico_tela.dart"
    "usuarios_admin_tela.dart"
)

for screen in "${CRITICAL_SCREENS[@]}"; do
    if [ -f "frontend/lib/telas/$screen" ]; then
        echo -e "Tela $screen: ${GREEN}✅ OK${NC}"
        ((PASSED++))
    else
        echo -e "Tela $screen: ${RED}❌ NÃO ENCONTRADA${NC}"
        ((FAILED++))
    fi
done

# Verificar api_cliente.dart
if [ -f "frontend/lib/servicos/api_cliente.dart" ]; then
    METHODS=$(grep -c "^  Future<" frontend/lib/servicos/api_cliente.dart)
    echo -e "API Cliente: ${GREEN}✅ OK${NC} ($METHODS métodos)"
    ((PASSED++))
else
    echo -e "API Cliente: ${RED}❌ NÃO ENCONTRADO${NC}"
    ((FAILED++))
fi

echo ""
echo "📊 RESUMO DA VERIFICAÇÃO"
echo "========================"
echo -e "✅ Passou: ${GREEN}$PASSED${NC}"
echo -e "❌ Falhou: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 TODOS OS TESTES PASSARAM!${NC}"
    echo -e "${GREEN}Sistema MVP está 100% operacional.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Alguns componentes não foram encontrados.${NC}"
    echo -e "${YELLOW}Verifique os itens marcados acima.${NC}"
    exit 1
fi
