-- Migração de dados das tabelas no singular para as tabelas no plural usadas pelo backend
-- Executar com: psql ... -f backend/scripts/sql/003_normalize_schema.sql

-- VAGA -> VAGAS
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='vaga') THEN
    INSERT INTO vagas (id, titulo, descricao, requisitos, status, criado_em)
    SELECT v.id,
           v.titulo,
           v.descricao,
           v.requisitos,
           v.status::text,
           COALESCE(v.data_criacao::timestamp, now())
    FROM vaga v
    ON CONFLICT DO NOTHING;
  END IF;
END$$;

-- CANDIDATO -> CANDIDATOS
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='candidato') THEN
    INSERT INTO candidatos (id, nome, email, github, criado_em)
    SELECT c.id,
           c.nome,
           c.email::text,
           NULL,
           COALESCE(c.created_at::timestamp, now())
    FROM candidato c
    ON CONFLICT DO NOTHING;
  END IF;
END$$;

-- CURRICULO -> CURRICULOS
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='curriculo') THEN
    INSERT INTO curriculos (id, candidato_id, nome_arquivo, mimetype, tamanho, texto, analise_json, criado_em)
    SELECT cu.id,
           cu.candidato_id,
           cu.arquivo_nome,
           cu.arquivo_tipo,
           cu.arquivo_tamanho,
           cu.texto_extraido,
           jsonb_strip_nulls(
             jsonb_build_object(
               'skills', cu.habilidades,
               'experiences', cu.experiencias,
               'education', cu.formacao,
               'keywords', to_jsonb(cu.competencias_chave),
               'languages', cu.idiomas,
               'summary', cu.resumo
             )
           ),
           COALESCE(cu.created_at::timestamp, now())
    FROM curriculo cu
    ON CONFLICT DO NOTHING;
  END IF;
END$$;

-- ENTREVISTA -> ENTREVISTAS
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='entrevista') THEN
    INSERT INTO entrevistas (id, vaga_id, candidato_id, curriculo_id, criado_em)
    SELECT e.id,
           e.vaga_id,
           e.candidato_id,
           e.curriculo_id,
           COALESCE(e.created_at::timestamp, now())
    FROM entrevista e
    ON CONFLICT DO NOTHING;
  END IF;
END$$;

-- PERGUNTA -> PERGUNTAS
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='pergunta') THEN
    INSERT INTO perguntas (id, entrevista_id, texto, criado_em)
    SELECT p.id,
           p.entrevista_id,
           COALESCE(p.descricao, p.contexto),
           COALESCE(p.created_at::timestamp, now())
    FROM pergunta p
    ON CONFLICT DO NOTHING;
  END IF;
END$$;

-- Depois de migrar os dados, remover tabelas duplicadas (no singular)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='pergunta') THEN
    EXECUTE 'DROP TABLE IF EXISTS pergunta CASCADE';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='entrevista') THEN
    EXECUTE 'DROP TABLE IF EXISTS entrevista CASCADE';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='curriculo') THEN
    EXECUTE 'DROP TABLE IF EXISTS curriculo CASCADE';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='candidato') THEN
    EXECUTE 'DROP TABLE IF EXISTS candidato CASCADE';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='vaga') THEN
    EXECUTE 'DROP TABLE IF EXISTS vaga CASCADE';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='relatorio') THEN
    EXECUTE 'DROP TABLE IF EXISTS relatorio CASCADE';
  END IF;
END$$;

