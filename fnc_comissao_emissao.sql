CREATE OR REPLACE FUNCTION fnc_comissao_emissao(id_vendedor bigint, data_inicio date, data_fim date)
RETURNS TABLE (
	cm_situacao text
	,cm_baixa_emissao text
	,cm_movto bigint
	,cm_financa_movto text
	,cm_tipo_documento varchar
	,cm_parcela text
	,cm_nota_fiscal integer
	,cm_modelo varchar
	,cm_serie varchar
	,cm_pessoa bigint
	,cm_pessoa__ps_nome_fantasia varchar
	,cm_dma_emissao date
	,cm_forma_pagamento varchar
	,filial bigint
	,cm_base_comissao numeric
	,cm_vendedor bigint
	,cm_vendedor__ps_nome_fantasia varchar
	,cm_percentual numeric
	,cm_valor numeric
) AS $$
	DECLARE comissao_com_impostos varchar;
	
	BEGIN
		comissao_com_impostos := (SELECT pm_valor FROM gb_parametro WHERE pm_codigo = 'PGF-COMISSAO-IMPOSTOS');

		RETURN QUERY
		SELECT
			cm.cm_situacao
			,cm.cm_baixa_emissao
			,cm.cm_movto
			,cm.cm_financa_movto
			,cm.cm_tipo_documento
			,cm.cm_parcela
			,cm.cm_nota_fiscal
			,cm.cm_modelo
			,cm.cm_serie
			,cm.cm_pessoa
			,cm.cm_pessoa__ps_nome_fantasia
			,cm.cm_dma_emissao
			,cm.cm_forma_pagamento
			,cm.filial
			,cm.cm_base_comissao
			,cm.cm_vendedor
			,cm.cm_vendedor__ps_nome_fantasia
			,cm.cm_percentual
			,cm.cm_valor
		FROM (
			SELECT
				'E' AS cm_situacao
				,'E' AS cm_baixa_emissao
				,mv.id AS cm_movto
				,null AS cm_financa_movto
				,mv.mv_entidade AS cm_tipo_documento
				,'1' AS cm_parcela
				,mv.mv_documento AS cm_nota_fiscal
				,mv.mv_modelo AS cm_modelo
				,mv.mv_serie AS cm_serie
				,mv.mv_pessoa_id AS cm_pessoa
				,cl.ps_nome_fantasia AS cm_pessoa__ps_nome_fantasia
				,mv.mv_dma_emissao AS cm_dma_emissao
				,mv.mv_forma_pagamento AS cm_forma_pagamento
				,mv.filial_id AS filial
				,CASE
					comissao_com_impostos
					WHEN 'N' THEN ROUND((mv.mv_total_bruto - mv.mv_valor_desconto)::numeric, 2)
					ELSE ROUND(mv.mv_total_nota_fiscal::numeric, 2)
				END AS cm_base_comissao
				,mv.mv_vendedor1_id AS cm_vendedor
				,vn.ps_nome_fantasia AS cm_vendedor__ps_nome_fantasia
				,ROUND((
					(
						(
							CASE comissao_com_impostos
								WHEN 'N' THEN ROUND(SUM((it.mt_valor_bruto - it.mt_valor_desconto) * (it.mt_percentual_comissao1 / 100)):: numeric, 2)
								ELSE ROUND(SUM(it.mt_valor_liquido - it.mt_valor_desconto * (it.mt_percentual_comissao1 / 100)):: numeric, 2)
							END
						) / (
							CASE comissao_com_impostos
								WHEN 'N' THEN ROUND((mv.mv_total_bruto - mv.mv_valor_desconto)::numeric, 2)
								ELSE ROUND(mv.mv_total_nota_fiscal::numeric, 2)
							END
						)
					) * 100
				)::numeric, 2) AS cm_percentual
				,CASE comissao_com_impostos
					WHEN 'N' THEN ROUND(SUM((it.mt_valor_bruto - it.mt_valor_desconto) * (it.mt_percentual_comissao1 / 100)):: numeric, 2)
					ELSE ROUND(SUM(it.mt_valor_liquido - it.mt_valor_desconto * (it.mt_percentual_comissao1 / 100)):: numeric, 2)
				END * CASE WHEN mv.mv_entidade = 'NFD' THEN -1 ELSE 1 END AS cm_valor
				,CASE WHEN COUNT(cm.id) = 0 THEN 'N' ELSE 'S' END AS comissao_gerada
			FROM
				mt_movto mv
				INNER JOIN mt_pessoa vn ON vn.id = mv.mv_vendedor1_id
				INNER JOIN mt_pessoa cl ON cl.id = mv.mv_pessoa_id
				INNER JOIN mt_movto_item it ON it.mt_movto_id = mv.id
				LEFT JOIN fn_comissao cm ON cm.cm_movto_id = mv.id AND cm.cm_vendedor_id = mv.mv_vendedor1_id
			WHERE
				mv.mv_entidade in ('NFE', 'NFD', 'NFS')
				AND mv.mv_dma_emissao BETWEEN data_inicio AND data_fim
				AND mv.mv_vendedor1_id = id_vendedor
				AND mv.mv_duplicata = 'S'
				AND mv.mv_total_nota_fiscal > 0
				AND vn.ps_tipo_comissao = 'E'
			GROUP BY
				mv.id
				,mv.mv_entidade
				,mv.mv_documento
				,mv.mv_modelo
				,mv.mv_serie
				,mv.mv_pessoa_id
				,cl.ps_nome_fantasia
				,mv.mv_dma_emissao
				,mv.mv_forma_pagamento
				,mv.filial_id
				,vn.ps_nome_fantasia
			UNION
			SELECT
				'E' AS cm_situacao
				,'E' AS cm_baixa_emissao
				,mv.id AS cm_movto
				,null AS cm_financa_movto
				,mv.mv_entidade AS cm_tipo_documento
				,'1' AS cm_parcela
				,mv.mv_documento AS cm_nota_fiscal
				,mv.mv_modelo AS cm_modelo
				,mv.mv_serie AS cm_serie
				,mv.mv_pessoa_id AS cm_pessoa
				,cl.ps_nome_fantasia AS cm_pessoa__ps_nome_fantasia
				,mv.mv_dma_emissao AS cm_dma_emissao
				,mv.mv_forma_pagamento AS cm_forma_pagamento
				,mv.filial_id AS filial
				,CASE comissao_com_impostos
					WHEN 'N' THEN ROUND((mv.mv_total_bruto - mv.mv_valor_desconto)::numeric, 2)
					ELSE ROUND(mv.mv_total_nota_fiscal::numeric, 2)
				END AS cm_base_comissao
				,mv.mv_vendedor2_id AS cm_vendedor
				,vn.ps_nome_fantasia AS cm_vendedor__ps_nome_fantasia
				,ROUND((
					(
						(
							CASE comissao_com_impostos
								WHEN 'N' THEN ROUND(SUM((it.mt_valor_bruto - it.mt_valor_desconto) * (it.mt_percentual_comissao2 / 100)):: numeric, 2)
								ELSE ROUND(SUM(it.mt_valor_liquido - it.mt_valor_desconto * (it.mt_percentual_comissao2 / 100)):: numeric, 2)
							END
						) / (
							CASE comissao_com_impostos
								WHEN 'N' THEN ROUND((mv.mv_total_bruto - mv.mv_valor_desconto)::numeric, 2)
								ELSE ROUND(mv.mv_total_nota_fiscal::numeric, 2)
							END
						)
					) * 100
				)::numeric, 2) AS cm_percentual
				,CASE comissao_com_impostos
					WHEN 'N' THEN ROUND(SUM((it.mt_valor_bruto - it.mt_valor_desconto) * (it.mt_percentual_comissao2 / 100)):: numeric, 2)
					ELSE ROUND(SUM(it.mt_valor_liquido - it.mt_valor_desconto * (it.mt_percentual_comissao2 / 100)):: numeric, 2)
				END * CASE WHEN mv.mv_entidade = 'NFD' THEN -1 ELSE 1 END AS cm_valor
				,CASE WHEN COUNT(cm.id) = 0 THEN 'N' ELSE 'S' END AS comissao_gerada
			FROM
				mt_movto mv
				INNER JOIN mt_movto_item it ON it.mt_movto_id = mv.id
				INNER JOIN mt_pessoa cl ON cl.id = mv.mv_pessoa_id
				INNER JOIN mt_pessoa vn ON vn.id = mv.mv_vendedor2_id
				LEFT JOIN fn_comissao cm ON cm.cm_movto_id = mv.id AND cm.cm_vendedor_id = mv.mv_vendedor2_id
			WHERE
				mv.mv_entidade in ('NFE', 'NFD', 'NFS')
				AND mv.mv_dma_emissao BETWEEN data_inicio AND data_fim
				AND mv.mv_vendedor2_id = id_vendedor
				AND mv.mv_duplicata = 'S'
				AND mv.mv_total_nota_fiscal > 0
				AND vn.ps_tipo_comissao = 'E'
			GROUP BY
				mv.id
				,mv.mv_entidade
				,mv.mv_documento
				,mv.mv_modelo
				,mv.mv_serie
				,mv.mv_pessoa_id
				,cl.ps_nome_fantasia
				,mv.mv_dma_emissao
				,mv.mv_forma_pagamento
				,mv.filial_id
				,vn.ps_nome_fantasia
		) AS cm
		WHERE
			cm.comissao_gerada = 'N';
	END;
$$ LANGUAGE plpgsql;
