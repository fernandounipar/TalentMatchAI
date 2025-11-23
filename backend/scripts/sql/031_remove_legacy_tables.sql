-- ============================================================================
-- Migration 031: Remoção de Tabelas Legacy (pt-BR)
-- ============================================================================
-- Remove tabelas antigas em português que não são mais usadas pelo backend
-- ATENÇÃO: Execute apenas após confirmar que o backend não depende dessas tabelas

-- ============================================================
-- BACKUP RECOMENDADO ANTES DA EXECUÇÃO
-- ============================================================
-- pg_dump -h localhost -U postgres -d talentmatchia \
--   -t mensagens -t perguntas -t relatorios -t entrevistas \
--   -t curriculos -t candidatos -t vagas \
--   > backup_tabelas_legacy_$(date +%Y%m%d).sql

-- ============================================================
-- Remoção das Tabelas Legacy
-- ============================================================

-- Tabela de mensagens legada
DROP TABLE IF EXISTS mensagens CASCADE;

-- Tabela de perguntas legada
DROP TABLE IF EXISTS perguntas CASCADE;

-- Tabela de relatórios legada
DROP TABLE IF EXISTS relatorios CASCADE;

-- Tabela de entrevistas legada
DROP TABLE IF EXISTS entrevistas CASCADE;

-- Tabela de currículos legada
DROP TABLE IF EXISTS curriculos CASCADE;

-- Tabela de candidatos legada
DROP TABLE IF EXISTS candidatos CASCADE;

-- Tabela de vagas legada
DROP TABLE IF EXISTS vagas CASCADE;

-- ============================================================
-- Verificação (opcional)
-- ============================================================

-- Listar tabelas restantes (deve retornar vazio se todas foram removidas)
DO $$
DECLARE
  legacy_tables TEXT[] := ARRAY['mensagens', 'perguntas', 'relatorios', 'entrevistas', 'curriculos', 'candidatos', 'vagas'];
  tbl TEXT;
  exists_count INT;
BEGIN
  RAISE NOTICE '=== Verificando remoção de tabelas legacy ===';
  
  FOREACH tbl IN ARRAY legacy_tables
  LOOP
    SELECT COUNT(*) INTO exists_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = tbl;
    
    IF exists_count = 0 THEN
      RAISE NOTICE '  ✓ % removida', tbl;
    ELSE
      RAISE NOTICE '  ✗ % ainda existe', tbl;
    END IF;
  END LOOP;
  
  RAISE NOTICE '=== Verificação completa ===';
END $$;

-- ============================================================
-- Migration 031 concluída
-- ============================================================
