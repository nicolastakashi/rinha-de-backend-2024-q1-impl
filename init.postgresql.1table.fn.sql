CREATE UNLOGGED TABLE transacoes (
	id SERIAL PRIMARY KEY,
	cliente_id INTEGER NOT NULL,
	valor INTEGER NOT NULL,
	tipo CHAR(1) NOT NULL,
	descricao VARCHAR(10) NOT NULL,
	realizada_em TIMESTAMP(6) NOT NULL,
    saldo INTEGER NOT NULL
);

INSERT INTO transacoes (cliente_id, valor, tipo, descricao, realizada_em, saldo) VALUES
    (1 , 0, 'c', 'init', clock_timestamp(), 0),
    (2 , 0, 'c', 'init', clock_timestamp(), 0),
    (3 , 0, 'c', 'init', clock_timestamp(), 0),
    (4 , 0, 'c', 'init', clock_timestamp(), 0),
    (5 , 0, 'c', 'init', clock_timestamp(), 0);


CREATE EXTENSION IF NOT EXISTS pg_prewarm;
SELECT pg_prewarm('transacoes');


CREATE OR REPLACE FUNCTION limite_cliente(p_cliente_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN CASE p_cliente_id
        WHEN 1 THEN 100000
        WHEN 2 THEN 80000
        WHEN 3 THEN 1000000
        WHEN 4 THEN 10000000
        WHEN 5 THEN 500000
        ELSE -1 -- Valor padrão caso o id do cliente não esteja entre 1 e 5
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TYPE transacao_result AS (saldo INT, limite INT);

CREATE OR REPLACE FUNCTION proc_transacao(p_cliente_id INT, p_valor INT, p_tipo CHAR, p_descricao VARCHAR(10))
RETURNS transacao_result as $$
DECLARE
    diff INT;
    v_saldo INT;
    v_limite INT;
    result transacao_result;
BEGIN
    -- PERFORM pg_try_advisory_xact_lock(42);
    -- PERFORM pg_advisory_lock(p_cliente_id);
    -- PERFORM pg_try_advisory_xact_lock(p_cliente_id);
    -- PERFORM pg_advisory_xact_lock(p_cliente_id);
    -- lock table clientes in ACCESS EXCLUSIVE mode;
    lock table transacoes in ACCESS EXCLUSIVE mode;

    -- invoke limite_cliente into v_limite
    SELECT limite_cliente(p_cliente_id) INTO v_limite;
    
    SELECT saldo 
        FROM transacoes
        WHERE cliente_id = p_cliente_id
        ORDER BY id DESC
        LIMIT 1
        INTO v_saldo;

    IF p_tipo = 'd' THEN
        diff := p_valor * -1;            
        IF (v_saldo + diff) < (-1 * v_limite) THEN
            RAISE 'LIMITE_INDISPONIVEL [%, %, %]', v_saldo, diff, v_limite;
        END IF;
    ELSE
        diff := p_valor;
    END IF;

    
    INSERT INTO transacoes 
                     (cliente_id,   valor,   tipo,   descricao,      realizada_em, saldo)
            VALUES (p_cliente_id, p_valor, p_tipo, p_descricao, clock_timestamp(), v_saldo + diff);

    result := (v_saldo + diff, v_limite)::transacao_result;
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE 'Error processing transaction: %', SQLERRM;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION proc_extrato(p_cliente_id int)
RETURNS json AS $$
DECLARE
    result json;
    row_count integer;
    v_saldo numeric;
    v_limite numeric;
BEGIN
    -- PERFORM pg_try_advisory_xact_lock(42);
    -- PERFORM pg_try_advisory_xact_lock(p_cliente_id);
    -- PERFORM pg_try_advisory_lock(p_cliente_id);
    -- PERFORM pg_advisory_xact_lock(p_cliente_id);
    -- lock table clientes in ACCESS EXCLUSIVE mode;
    lock table transacoes in ACCESS SHARE mode;

    SELECT saldo 
        FROM transacoes
        WHERE cliente_id = p_cliente_id
        ORDER BY id DESC
        LIMIT 1
        INTO v_saldo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'CLIENTE_NAO_ENCONTRADO %', p_cliente_id;
    END IF;

    SELECT limite_cliente(p_cliente_id) INTO v_limite;
    SELECT json_build_object(
        'saldo', json_build_object(
            'total', v_saldo,
            'data_extrato', TO_CHAR(clock_timestamp(), 'YYYY-MM-DD HH:MI:SS.US'),
            'limite', v_limite
        ),
        'ultimas_transacoes', COALESCE((
            SELECT json_agg(row_to_json(t)) FROM (
                SELECT valor, tipo, descricao, TO_CHAR(realizada_em, 'YYYY-MM-DD HH:MI:SS.US') as realizada_em
                FROM transacoes
                WHERE cliente_id = p_cliente_id
                ORDER BY realizada_em DESC
                -- ORDER BY id DESC
                LIMIT 10
            ) t
        ), '[]')
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;
-- SQL init done